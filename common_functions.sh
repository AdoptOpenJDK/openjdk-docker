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

# Config files
tags_config_file="config/tags.config"
openj9_config_file="config/openj9.config"
hotspot_config_file="config/hotspot.config"

# Test lists
test_image_types_file="config/test_image_types.list"
test_image_types_all_file="config/test_image_types_all.list"
test_buckets_file="config/test_buckets.list"

# All supported JVMs
all_jvms="hotspot openj9"

# All supported arches
all_arches="aarch64 ppc64le s390x x86_64"

# Current JVM versions supported
export supported_versions="8 9 10 11"

# Current builds supported
export supported_builds="releases nightly"

function check_version() {
	version=$1
	case ${version} in
	8|9|10|11)
		;;
	*)
		echo "ERROR: Invalid version"
		;;
	esac
}

# Set a valid version
function set_version() {
	version=$1
	if [ ! -z "$(check_version ${version})" ]; then
		echo "ERROR: Invalid Version: ${version}"
		echo "Usage: $0 [${supported_versions}]"
		exit 1
	fi
}

# Set the valid OSes for the current architecure.
function set_arch_os() {
	machine=`uname -m`
	case ${machine} in
	aarch64)
		current_arch="aarch64"
		oses="ubuntu"
		package="jdk"
		;;
	ppc64el|ppc64le)
		current_arch="ppc64le"
		oses="ubuntu"
		package="jdk"
		;;
	s390x)
		current_arch="s390x"
		oses="ubuntu"
		package="jdk"
		;;
	amd64|x86_64)
		current_arch="x86_64"
		oses="ubuntu alpine"
		package="jdk"
		;;
	*)
		echo "ERROR: Unsupported arch:${machine}, Exiting"
		exit 1
		;;
	esac
}

# Get the supported architectures for a given VM (Hotspot, OpenJ9).
# This is based on the hotspot_shasums_latest.sh/openj9_shasums_latest.sh
function get_arches() {
	# Check if the array has been defined. Array might be undefined if the
	# corresponding build combination does not exist.
	# Eg. jdk_openj9_10_releases_sums does not exist as we do not have any
	# release builds for version 10 (Only nightly builds).
	declare -p $1 >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return;
	fi
	archsums="$(declare -p $1)";
	eval "declare -A sums="${archsums#*=};
	for arch in ${!sums[@]};
	do
		if [ "${arch}" == "version" ]; then
			continue;
		fi
		# Arch is supported only if the shasum is not empty !
		shasum=$(sarray=$1[${arch}]; eval esum=\${$sarray}; echo ${esum});
		if [ ! -z "${shasum}" ]; then
			echo "${arch} "
		fi
	done
}

# Check if the given VM is supported on the current architecture.
# This is based on the hotspot_shasums_latest.sh/openj9_shasums_latest.sh
function vm_supported_onarch() {
	vm=$1
	sums=$2

	if [ ! -z "$3" ]; then
		test_arch=$3;
	else
		test_arch=`uname -m`
	fi

	suparches=$(get_arches ${sums})
	sup=$(echo ${suparches} | grep ${test_arch})
	echo ${sup}
}

function cleanup_images() {
	# Delete any old containers that have exited.
	docker rm $(docker ps -a | grep "Exited" | awk '{ print $1 }') 2>/dev/null

	# Delete any old images for our target_repo on localhost.
	docker rmi -f $(docker images | grep -e "adoptopenjdk" | awk '{ print $3 }' | sort | uniq) 2>/dev/null
}

function cleanup_manifest() {
	# Remove any previously created manifest lists.
	# Currently there is no way to do this using the tool.
	rm -rf ~/.docker/manifests
}

# Check if a given docker image exists on the server.
# This script errors out if the image does not exist.
function check_image() {
	img=$1

	echo -n "INFO: Pulling image: ${img}..."
	docker pull ${img} >/dev/null
	if [ $? != 0 ]; then
		echo "ERROR: Docker Image ${img} not found on hub.docker\n"
		exit 1
	fi
	echo "done"
}

# Parse the openj9.config / hotspot.config file for an entry as specified by $4
# $1 = VM
# $2 = Version
# $3 = OS
# $4 = String to look for.
function parse_vm_entry() {
	entry=$(cat config/$1.config | grep -B 4 "$2\/.*\/$3" | grep "$4" | sed "s/$4 //")
	echo ${entry}
}

# Parse the openj9.config / hotspot.config file for the supported OSes
# $1 = VM
function parse_os_entry() {
	entry=$(cat config/$1.config | grep "^OS:" | sed "s/OS: //")
	echo ${entry}
}

# Read the tags file and parse the specific tag.
# $1 = OS
# $2 = Build (releases / nightly)
# $3 = Type (full / slim)
function parse_tag_entry() {
	tag="$1-$2-$3-tags:"
	entry=$(cat ${tags_config_file} | grep ${tag} | sed "s/${tag} //")
	echo ${entry}
}

# Where is the manifest tool installed?"
# Manifest tool (docker with manifest support) needs to be added from here
# https://github.com/clnperez/cli
# $ cd /opt/manifest_tool
# $ git clone -b manifest-cmd https://github.com/clnperez/cli.git
# $ cd cli
# $ make -f docker.Makefile cross
manifest_tool_dir="/opt/manifest_tool"
manifest_tool=${manifest_tool_dir}/cli/build/docker

function check_manifest_tool() {
	if [ ! -f ${manifest_tool} ]; then
		echo
		echo "ERROR: Docker with manifest support not found at path ${manifest_tool}"
		exit 1
	fi
}

# Build valid image tags using the tags.config file as the base
function build_tags() {
	vm=$1; shift
	ver=$1; shift;
	rel=$1; shift;
	os=$1; shift;
	build=$1; shift;
	rawtags=$*
	tmpfile=raw_arch_tags.$$.tmp

	# Get the list of supported arches for this vm / ver /os combo
	arches=$(parse_vm_entry ${vm} ${ver} ${os} "Architectures:")
	# Replace the proper version string in the tags
	rtags=$(echo ${rawtags} | sed "s/{{ JDK_${build}_VER }}/${rel}/gI; s/{{ OS }}/${os}/gI;");
	echo ${rtags} | sed "s/{{ *ARCH *}}/{{ARCH}}/" |
	# Separate the arch and the generic alias tags
	awk '{ a=0; n=0;
		for (i=1; i<=NF; i++) {
			if (match($i, "ARCH") > 0) {
				atags[a++]=sprintf(" %s", $i);
			} else {
				natags[n++]=sprintf(" %s", $i);
			}
		}
	} END {
		printf("arch_tags: "); for (key in atags) { printf"%s ", atags[key] }; printf"\n";
		printf("tag_aliases: "); for (key in natags) { printf"%s ", natags[key] }; printf"\n";
	}' > ${tmpfile}

	tag_aliases=$(cat ${tmpfile} | grep "^tag_aliases:" | sed "s/tag_aliases: //")
	raw_arch_tags=$(cat ${tmpfile} | grep "^arch_tags:" | sed "s/arch_tags: //")
	arch_tags=""
	# Iterate through the arch tags and expand to add the supported arches.
	for tag in ${raw_arch_tags}
	do
		for arch in ${arches}
		do
			# Check if all the supported arches are available for this build.
			supported=$(vm_supported_onarch ${vm} ${shasums} ${arch})
			if [ -z "${supported}" ]; then
				continue;
			fi
			atag=$(echo ${tag} | sed "s/{{ARCH}}/${arch}"/g)
			arch_tags="${arch_tags} ${atag}"
		done
	done
	rm -f ${tmpfile}
}

# Build the URL using adoptopenjdk.net v2 api based on the given parameters
# request_type = info / binary
# release_type = releases / nightly
# url_impl = hotspot / openj9
# url_arch = aarch64 / ppc64le / s390x / x64 
# url_pkg  = jdk / jre
# url_rel  = latest / ${version}
function get_v2_url() {
	request_type=$1
	release_type=$2
	url_impl=$3
	url_pkg=$4
	url_rel=$5
	url_arch=$6
	url_os=linux
	url_heapsize=normal
	url_version=openjdk${version}
	
	baseurl="https://api.adoptopenjdk.net/v2/${request_type}/${release_type}/${url_version}"
	specifiers="openjdk_impl=${url_impl}&os=${url_os}&type=${url_pkg}&release=${url_rel}&heap_size=${url_heapsize}"
	if [ ! -z "${url_arch}" ]; then
		specifiers="${specifiers}&arch=${url_arch}"
	fi
	
	echo "${baseurl}?${specifiers}"
}

# Get the shasums for the given specific build and arch combination.
function get_sums_for_build_arch() {
	gsba_ver=$1
	gsba_vm=$2
	gsba_build=$3
	gsba_arch=$4

	case ${gsba_arch} in
		aarch64)
			LATEST_URL=$(get_v2_url info ${gsba_build} ${gsba_vm} jdk latest aarch64);
			;;
		ppc64le)
			LATEST_URL=$(get_v2_url info ${gsba_build} ${gsba_vm} jdk latest ppc64le);
			;;
		s390x)
			LATEST_URL=$(get_v2_url info ${gsba_build} ${gsba_vm} jdk latest s390x);
			;;
		x86_64)
			LATEST_URL=$(get_v2_url info ${gsba_build} ${gsba_vm} jdk latest x64);
			;;
		*)
			echo "Unsupported arch: ${gsba_arch}"
	esac
	shasum_file="${gsba_arch}_${gsba_build}_latest"
	curl -Lso ${shasum_file} ${LATEST_URL};
	# Bad builds cause the latest url to return an empty file or sometimes curl fails
	if [ $? -ne 0 -o ! -s ${shasum_file} ]; then
		continue;
	fi
	# Even if the file is not empty, it might just say "No matches"
	availability=$(grep -e "No matches" -e "Not found" ${shasum_file});
	# Print the arch and the corresponding shasums to the vm output file
	if [ -z "${availability}" ]; then
		# If there are multiple builds for a single version, then pick the latest one.
		shasums_url=$(cat ${shasum_file} | grep "checksum_link" | head -1 | awk -F'"' '{ print $4 }');
		shasum=$(curl -Ls ${shasums_url} | sed -e 's/<[^>]*>//g' | awk '{ print $1 }');
		# Only print the entry if the shasum is not empty
		if [ ! -z "${shasum}" ]; then
			printf "\t[%s]=\"%s\"\n" ${gsba_arch} ${shasum} >> ${ofile}
		fi
	fi
	rm -f ${shasum_file}
}

# Get shasums for the build and arch combination given
# If no arch given, generate for all valid arches
function get_sums_for_build() {
	gsb_ver=$1
	gsb_vm=$2
	gsb_build=$3
	gsb_arch=$4

	info_url=$(get_v2_url info ${gsb_build} ${gsb_vm} jdk latest);
	# Repeated requests from a script triggers a error threshold on adoptopenjdk.net
	sleep 1;
	info=$(curl -Ls ${info_url})
	err=$(echo ${info} | grep -e "Error" -e "No matches" -e "Not found")
	if [ ! -z "${err}" ]; then
		continue;
	fi
	full_version=$(echo ${info} | grep "release_name" | awk -F'"' '{ print $4 }');
	if [ "${build}" == "nightly" ]; then
		# Remove date and time at the end of full_version for nightly builds.
		# Handle both the old and new date-time formats used by the Adopt build system.
		# Older date-time format - 201809270034
		full_version=$(echo ${full_version} | sed 's/-[0-9]\{4\}[0-9]\{2\}[0-9]\{2\}[0-9]\{4\}$//')
		# New date-time format   - 2018-09-27-00-34
		full_version=$(echo ${full_version} | sed 's/-[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}$//')
	fi
	# Declare the array with the proper name and write to the vm output file.
	printf "declare -A jdk_%s_%s_%s_sums=(\n" ${gsb_vm} ${gsb_ver} ${gsb_build} >> ${ofile}
	# Capture the full version according to adoptopenjdk
	printf "\t[version]=\"%s\"\n" ${full_version} >> ${ofile}
	if [ ! -z "${gsb_arch}" ]; then
		get_sums_for_build_arch ${gsb_ver} ${gsb_vm} ${gsb_build} ${gsb_arch}
	else
		for gsb_arch in ${all_arches}
		do
			get_sums_for_build_arch ${gsb_ver} ${gsb_vm} ${gsb_build} ${gsb_arch}
		done
	fi
	printf ")\n" >> ${ofile}

	echo
	echo "sha256sums for the version ${full_version} for build type \"${gsb_build}\" is now available in ${ofile}"
	echo
}

# get sha256sums for the specific builds and arches given.
# If no build or arch specified, do it for all valid ones.
function get_shasums() {
	ver=$1
	vm=$2
	build=$3
	arch=$4
	ofile="${root_dir}/${vm}_shasums_latest.sh"

	if [ ! -z "${build}" ]; then
		get_sums_for_build ${ver} ${vm} ${build} ${arch}
	else
		for build in ${supported_builds}
		do
			get_sums_for_build ${ver} ${vm} ${build} ${arch}
		done
	fi
	chmod +x ${ofile}
}
