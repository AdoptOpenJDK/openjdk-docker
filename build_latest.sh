#!/usr/bin/env bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -o pipefail

if [[ -z ${root_dir} ]]; then
	export root_dir="$PWD"
fi

push_cmdfile=${root_dir}/push_commands.sh

if [[ -z ${summary_table_file} ]]; then
	export summary_table_file=${root_dir}/.summary_table
fi

target_repo="adoptopenjdk/openjdk"
version="9"

# shellcheck source=common_functions.sh
source ./common_functions.sh
# shellcheck source=snyk.sh
source ./snyk.sh

# shellcheck source=dockerfile_functions.sh
source ./dockerfile_functions.sh

if [ $# -ne 4 ]; then
	echo
	echo "usage: $0 version vm package runtype"
	echo "version = ${supported_versions}"
	echo "vm      = ${all_jvms}"
	echo "package = ${all_packages}"
	echo "runtype = ${all_runtypes}"
	exit 1
fi

set_version "$1"
vm="$2"
package="$3"
set_runtype "$4"

# Get the image build time stored in the "build_time" array for the current arch
# Build time is stored as the time since 1-1-1970
function get_image_build_time() {
	local osfamily=$2

	if ! declare -p "$1" &>/dev/null; then
		return;
	fi

	# shellcheck disable=SC2154,SC1083
	btime=$(btarray=$1[${osfamily}_${current_arch}]; eval btarch=\${"$btarray"}; echo "${btarch}");

	echo "${btime}"
}

# Check if the adopt image is available, if not need to build it.
function check_adopt_image_available() {
	local image_name=$1

	echo "INFO: Checking when the adopt docker image ${image_name} was built ..."
	if ! docker pull "${image_name}" &>/dev/null; then
		# Adopt image not available currently, build needed
		echo "INFO: AdoptOpenJDK docker image for ${image_name} does not exist. Docker build needed"
		build_needed=1
		return;
	fi
}

# Check if we have a newer base OS docker image
# If a new base OS docker image was built in the last 24 hrs, then we need to rebuild the adopt docker image
function check_new_os_image_available() {
	local image_name=$2

	# Get the date when the base image was created. Eg if the base OS is ubuntu, this
	# translates as the exact date/time when the Ubuntu image was created on DockerHub
	from_image="$(grep "FROM" "$1" | awk '{ print $2 }')"
	# Pull the latest image locally
	echo "INFO: Checking when the base docker image ${from_image} was built ..."
	if ! docker pull "${from_image}" &>/dev/null; then
		echo "INFO: Failed to pull base docker image. Docker build needed"
		build_needed=1
		return;
	fi

	# Get the shasums of the base OS image layers
	docker inspect "${from_image}" > base_os_image.info
	base_os_sha_arr="$(python3 <<EOF
import sys, json;
input_file = open ('base_os_image.info');
sha_arr = json.load(input_file)[0]['RootFS']['Layers'];
for ssum in sha_arr:
    print(ssum);
EOF
	)"

	# Get the shasums of the current Adopt Image layers
	docker inspect "${image_name}" > adopt_image.info
	adopt_sha_arr="$(python3 <<EOF
import sys, json;
input_file = open ('adopt_image.info');
sha_arr = json.load(input_file)[0]['RootFS']['Layers'];
for ssum in sha_arr:
    print(ssum);
EOF
    )"

	# Check if each of the latest base os image layer is present in the Adopt Image
	for ssum in ${base_os_sha_arr}
	do
		if ! echo "${adopt_sha_arr}" | grep -q "${ssum}" ; then
			echo "Base OS layer ${ssum} not found in Adopt Image: ${image_name}"
			# Layer missing in the current Adopt Image, rebuild needed
			build_needed=1
			break;
		fi
	done
	# Remove tmp files
	rm -f base_os_image.info adopt_image.info
}

# Check if we have a newer adopt build tarball
function check_new_adopt_build_available() {
	local osfamily=$1
	local image_name=$2

	# Get the last build date for the current arch from the "build_time" array
	adopt_last_build_date=$(get_image_build_time "${build_time}" "${osfamily}")
	if [ -z "${adopt_last_build_date}" ]; then
		echo "INFO: Unknown last tarball build time. Docker build needed"
		build_needed=1
		return;
	fi
	# Add "one day" to it, this is to ensure that we rebuild our image if the last build date was in the past 24 hours
	adopt_last_build_date=$(( adopt_last_build_date + 86400 ))

	# check when the adopt image was last built
	adopt_image_creation="$(docker inspect "${image_name}" | python3 -c "import sys, json; print(json.load(sys.stdin)[0]['Created'])")"
	# Convert this to seconds since 1-1-1970
	adopt_image_creation_date="$(date --date="${adopt_image_creation}" +%s)"

	echo "INFO: Current docker image for ${image_name} build date: $(date --date="@${adopt_image_creation_date}")"
	echo "INFO: Current adopt build tarball related to ${image_name} build date: $(date --date="@${adopt_last_build_date}")"
	if [[ ${adopt_image_creation_date} -le ${adopt_last_build_date} ]]; then
		# build needed
		echo "INFO: Newer adopt build found. Docker build needed"
		build_needed=1
		return;
	fi
}

# Check if we need to do a docker build
# Build is needed only if one of the following criteria is met
# 1. If no such docker image exists currently
# 2. If the base OS docker image was recently re-built
# 3. If a new Adopt build is found
# 4. On any other error condition
function check_build_needed() {
	local osfamily=$2
	local image_name=$3

	echo "Checking build for image_name: ${image_name}"
	build_needed=0

	# `runtype` flag specifies if the script is being run for `build` or `test` (PR checks)
	# Checking for runtype if its `test` we proceed to build release images, as part of PR checks
	if [ "${runtype}" == "test" ]; then
		if [ "${build}" == "releases" ]; then
			build_needed=1
		fi
		return;
	fi

	# For nightly images, check if a newer adopt nightly build is available.
	if [ "${build}" == "nightly" ]; then
		# Check if we have a newer adopt build tarball
		check_new_adopt_build_available "${osfamily}" "${image_name}"
		if [[ ${build_needed} -eq 1 ]]; then
			return;
		fi
	fi

	# Check if the adopt image is available, if not need to build it.
	check_adopt_image_available "${image_name}"
	if [[ ${build_needed} -eq 1 ]]; then
		return;
	fi

	# Check if we have a newer base OS Image
	check_new_os_image_available "$1" "${image_name}"
	if [[ ${build_needed} -eq 1 ]]; then
		return;
	fi

	# Check if we have a newer adopt build tarball
	check_new_adopt_build_available "${osfamily}" "${image_name}"
	if [[ ${build_needed} -eq 1 ]]; then
		return;
	fi

	# build not needed
	echo "INFO: Docker image for ${image_name} exists and is latest. Docker build NOT needed"
}

# Build the Docker image with the given repo, build, build type and tag.
function build_image() {
	local repo=$1;
	local build=$2;
	local btype=$3;
	local osfamily=$4;
	local tag=$5;

	local dockerfile="Dockerfile.${vm}.${build}.${btype}"
	local image_name="${repo}:${tag}"
	check_build_needed "${dockerfile}" "${osfamily}" "${image_name}"
	# Check if we need to build this image.
	if [[ ${build_needed} -eq 0 ]]; then
		# No build needed, we are done
		return;
	fi

	auto_space_line="                                                                              "
	printf -v expanded_tags "%s ${repo}:%s " "-t" "${tag}" # concatenate to single string : -t repo:tag -t repo:tag2
	expanded_tags=${expanded_tags%?} # remove trailing space

	echo "docker push ${image_name}" >> "${push_cmdfile}"
	echo "#####################################################"
	echo "INFO: docker build --no-cache ${expanded_tags} -f ${dockerfile} ."
	echo "#####################################################"
	if [ ! -z "$TARGET_ARCHITECTURE" ]; then
		echo "using a buildx environment"
		export DOCKER_CLI_EXPERIMENTAL="enabled"
		docker buildx create --name mbuilder
		docker buildx use mbuilder
		docker buildx inspect --bootstrap
		# shellcheck disable=SC2086 # ignoring ${tags} due to whitespace problem
		if ! docker buildx build --platform "$TARGET_ARCHITECTURE" --pull --no-cache ${expanded_tags} -f "${dockerfile}" . ; then
			echo "#############################################"
			echo
			echo "ERROR: Docker build of image: ${expanded_tags} from ${dockerfile} failed."
			echo
			echo "#############################################"
			echo "| ${image_name:0:80}${auto_space_line:0:$((76 - ${#image_name}))} | failure  |" >> ${summary_table_file}
			echo "+------------------------------------------------------------------------------+----------+" >> ${summary_table_file}
			if [ "${runtype}" == "test" ]; then
				cleanup_images
				cleanup_manifest
				exit 1
			fi
		else
			if ((SNYK_ENABLED)); then
			echo "#####################################################"
			echo "        Scanning with snyk for vulnerabilities       "
			echo "#####################################################"
				echo "...scanning ${image_name}"
				snyk test --docker "${image_name}" --file="${dockerfile}"
			fi
			echo "| ${image_name:0:80}${auto_space_line:0:$((76 - ${#image_name}))} | success  |" >> ${summary_table_file}
			echo "+------------------------------------------------------------------------------+----------+" >> ${summary_table_file}
		fi

		docker buildx rm mbuilder
	else
		# shellcheck disable=SC2086 # ignoring ${tags} due to whitespace problem
		if ! docker build --pull --no-cache ${expanded_tags} -f "${dockerfile}" . ; then
			echo "#############################################"
			echo
			echo "ERROR: Docker build of image: ${expanded_tags} from ${dockerfile} failed."
			echo
			echo "#############################################"
			echo "| ${image_name:0:80}${auto_space_line:0:$((76 - ${#image_name}))} | failure  |" >> ${summary_table_file}
			echo "+------------------------------------------------------------------------------+----------+" >> ${summary_table_file}
			if [ "${runtype}" == "test" ]; then
				cleanup_images
				cleanup_manifest
				exit 1
			fi
		else
		  if ((SNYK_ENABLED)); then
			echo "#####################################################"
			echo "        Scanning with snyk for vulnerabilities       "
			echo "#####################################################"
				echo "...scanning ${image_name}"
				snyk test --docker "${image_name}" --file="${dockerfile}"
			fi
			echo "| ${image_name:0:80}${auto_space_line:0:$((76 - ${#image_name}))} | success  |" >> ${summary_table_file}
			echo "+------------------------------------------------------------------------------+----------+" >> ${summary_table_file}
		fi
	fi
}

# Build the docker image for a given VM, OS, BUILD and BUILD_TYPE combination.
function build_dockerfile {
	local vm=$1;
	local pkg=$2;
	local build=$3;
	local btype=$4;
	local osfamily=$5;
	local os=$6;

	local tag=""
	echo "INFO: current_arch: ${current_arch}, osfamily: ${osfamily}, os: ${os}"
	if [ -z "${current_arch}" ]; then
		jverinfo="${shasums}[version]"
	else
		jverinfo="${shasums}[version-${osfamily}_${current_arch}]"
	fi
	# shellcheck disable=SC1083,SC2086
	eval jrel=\${$jverinfo}
	echo "INFO: release: ${jrel}"
	# Docker image tags cannot have "+" in them, replace it with "_" instead.
	# shellcheck disable=SC2154
	rel=${jrel//+/_}
	if [ "${pkg}" == "jre" ]; then
		rel=${rel//jdk/jre}
	fi

	# The target repo is different for different VMs
	if [ "${vm}" == "hotspot" ]; then
		trepo=${target_repo}${version}
	else
		trepo=${target_repo}${version}-${vm}
	fi
	# Get the default tag first
	nanoserver_pat=".*nanoserver.*"
	if [[ "$file" =~ $nanoserver_pat ]]; then
		tag=${current_arch}-${os}-nanoserver-${rel}
	else
		tag=${current_arch}-${os}-${rel}
	fi
	# Append nightly for nightly builds
	if [ "${build}" == "nightly" ]; then
		tag=${tag}-nightly
	fi
	# Append slim for slim builds
	if [ "${btype}" == "slim" ]; then
		tag=${tag}-slim
		# Copy the script to generate slim builds.
		if [ "${osfamily}" == "windows" ]; then
		    cp slim-java.ps1 config/slim-java* "${dir}"/
		else
		    cp slim-java.sh config/slim-java* "${dir}"/
		fi
	fi
	echo "INFO: Building ${trepo} ${tag} from $file ..."
	pushd "${dir}" >/dev/null || return
	build_image "${trepo}" "${build}" "${btype}" "${osfamily}" "${tag}"
	popd >/dev/null || return
}

# Set the OSes that will be built on based on the current arch
set_arch_os

# Updating `oses` for `test` runtype to reduce the build time for OpenJ9 images for PR checks
if [ "${runtype}" == "test" ] && [ "${vm}" == "openj9" ] && [ "${current_arch}" == "x86_64" ] && [ "${os_family}" == "linux" ]; then
	oses="${PR_TEST_OSES}"
fi

# Script that has the push commands for the images that we are building.
echo "#!/usr/bin/env bash" > "${push_cmdfile}"
echo >> "${push_cmdfile}"

# Valid image tags
#adoptopenjdk/openjdk${version}:${arch}-${os}-${rel}
#adoptopenjdk/openjdk${version}:${arch}-${os}-${rel}-slim
#adoptopenjdk/openjdk${version}:${arch}-${os}-${rel}-nightly
#adoptopenjdk/openjdk${version}:${arch}-${os}-${rel}-nightly-slim
#adoptopenjdk/openjdk${version}-openj9:${arch}-${os}-${rel}
#adoptopenjdk/openjdk${version}-openj9:${arch}-${os}-${rel}-slim
#adoptopenjdk/openjdk${version}-openj9:${arch}-${os}-${rel}-nightly
#adoptopenjdk/openjdk${version}-openj9:${arch}-${os}-${rel}-nightly-slim
for os in ${oses}
do
	# Build = Release or Nightly
	builds=$(parse_vm_entry "${vm}" "${version}" "${package}" "${os}" "Build:")
	# Type = Full or Slim
	btypes=$(parse_vm_entry "${vm}" "${version}" "${package}" "${os}" "Type:")
	dir=$(parse_vm_entry "${vm}" "${version}" "${package}" "${os}" "Directory:")
	osfamily=$(parse_vm_entry "${vm}" "${version}" "${package}" "${os}" "OS_Family:")

	for build in ${builds}
	do
		echo "Getting latest shasum info for [ ${version} ${vm} ${package} ${build} ]"
		get_shasums "${version}" "${vm}" "${package}" "${build}"
		# Source the generated shasums file to access the array
		if [ -f "${vm}"_shasums_latest.sh ]; then
			# shellcheck disable=SC1090
			source ./"${vm}"_shasums_latest.sh
			# shellcheck disable=SC1090
			source ./"${vm}"_build_time_latest.sh
		else
			continue;
		fi
		# Check if the VM is supported for the current arch
		shasums="${package}"_"${vm}"_"${version}"_"${build}"_sums
		build_time="${package}"_"${vm}"_"${version}"_"${build}"_build_time
		sup=$(vm_supported_onarch_config "${vm}" "${shasums}" "${version}" "${package}" "${os}")
		if [ -z "${sup}" ]; then
			continue;
		fi
		# Generate all the Dockerfiles for each of the builds and build types
		for btype in ${btypes}
		do
			file="${dir}/Dockerfile.${vm}.${build}.${btype}"
			generate_dockerfile "${file}" "${package}" "${build}" "${btype}" "${osfamily}" "${os}"
			if [ ! -f "${file}" ]; then
				continue;
			fi
			# Build the docker images for valid Dockerfiles
			build_dockerfile "${vm}" "${package}" "${build}" "${btype}" "${osfamily}" "${os}"
		done
	done
done
chmod +x "${push_cmdfile}"

echo
echo "INFO: The push commands are available in file ${push_cmdfile}"
