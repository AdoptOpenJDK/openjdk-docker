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

root_dir="$PWD"
push_cmdfile=${root_dir}/push_commands.sh
target_repo="adoptopenjdk/openjdk"
version="9"

source ./common_functions.sh
source ./dockerfile_functions.sh

# Build the Docker image with the given repo, build, build type and tags.
function build_image() {
	repo=$1; shift;
	build=$1; shift;
	btype=$1; shift;

	tags=""
	for tag in $*
	do
		tags="${tags} -t ${repo}:${tag}"
		echo "docker push ${repo}:${tag}" >> ${push_cmdfile}
	done

	dockerfile="Dockerfile.${vm}.${build}.${btype}"

	echo "#####################################################"
	echo "INFO: docker build --no-cache ${tags} -f ${dockerfile} ."
	echo "#####################################################"
	docker build --no-cache ${tags} -f ${dockerfile} .
	if [ $? != 0 ]; then
		echo "ERROR: Docker build of image: ${tags} from ${dockerfile} failed."
		exit 1
	fi
}

# Build the docker image for a given VM, OS, BUILD and BUILD_TYPE combination.
function build_dockerfile {
	vm=$1; os=$2; build=$3; btype=$4;

	jverinfo=${shasums}[version]
	eval jrel=\${$jverinfo}
	# Docker image tags cannot have "+" in them, replace it with "." instead.
	rel=$(echo ${jrel} | sed 's/+/./')

	# The target repo is different for different VMs
	if [ "${vm}" == "hotspot" ]; then
		trepo=${target_repo}${version}
	else
		trepo=${target_repo}${version}-${vm}
	fi
	# Get the default tag first
	tag=${current_arch}-${os}-${rel}
	# Append nightly for nightly builds
	if [ "${build}" == "nightly" ]; then
		tag=${tag}-nightly
	fi
	# Append slim for slim builds
	if [ "${btype}" == "slim" ]; then
		tag=${tag}-slim
		# Copy the script to generate slim builds.
		cp slim-java* config/slim-java* ${dir}/
	fi
	echo "INFO: Building ${trepo} ${tag} from $file ..."
	pushd ${dir} >/dev/null
	build_image ${trepo} ${build} ${btype} ${tag}
	popd >/dev/null
}

if [ ! -z "$1" ]; then
	set_version $1
fi

# Set the OSes that will be built on based on the current arch
set_arch_os

# Script that has the push commands for the images that we are building.
echo "#!/usr/bin/env bash" > ${push_cmdfile}
echo >> ${push_cmdfile}

# Valid image tags
#adoptopenjdk/openjdk${version}:${arch}-${os}-${rel}
#adoptopenjdk/openjdk${version}:${arch}-${os}-${rel}-slim
#adoptopenjdk/openjdk${version}:${arch}-${os}-${rel}-nightly
#adoptopenjdk/openjdk${version}:${arch}-${os}-${rel}-nightly-slim
#adoptopenjdk/openjdk${version}-openj9:${arch}-${os}-${rel}
#adoptopenjdk/openjdk${version}-openj9:${arch}-${os}-${rel}-slim
#adoptopenjdk/openjdk${version}-openj9:${arch}-${os}-${rel}-nightly
#adoptopenjdk/openjdk${version}-openj9:${arch}-${os}-${rel}-nightly-slim
for vm in ${all_jvms}
do
	for os in ${oses}
	do
		# Build = Release or Nightly
		builds=$(parse_vm_entry ${vm} ${version} ${os} "Build:")
		# Type = Full or Slim
		btypes=$(parse_vm_entry ${vm} ${version} ${os} "Type:")
		dir=$(parse_vm_entry ${vm} ${version} ${os} "Directory:")

		for build in ${builds}
		do
			echo "Getting latest shasum info for [ ${version} ${vm} ${build} ]"
			get_shasums ${version} ${vm} ${build}
			# Source the generated shasums file to access the array
			if [ -f ${vm}_shasums_latest.sh ]; then
				source ./${vm}_shasums_latest.sh
			else
				continue;
			fi
			# Check if the VM is supported for the current arch
			shasums="${package}"_"${vm}"_"${version}"_"${build}"_sums
			sup=$(vm_supported_onarch ${vm} ${shasums})
			if [ -z "${sup}" ]; then
				continue;
			fi
			# Generate all the Dockerfiles for each of the builds and build types
			for btype in ${btypes}
			do
				file="${dir}/Dockerfile.${vm}.${build}.${btype}"
				generate_dockerfile ${file} ${build} ${btype} ${os}
				if [ ! -f ${file} ]; then
					continue;
				fi
				# Build the docker images for valid Dockerfiles
				build_dockerfile ${vm} ${os} ${build} ${btype}
			done
		done
	done
done
chmod +x ${push_cmdfile}

echo
echo "INFO: The push commands are available in file ${push_cmdfile}"
