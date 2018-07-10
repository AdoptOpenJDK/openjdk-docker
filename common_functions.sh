#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Config files
tags_config_file="tags.config"
openj9_config_file="openj9.config"
hotspot_config_file="hotspot.config"

# All supported JVMs
all_jvms="hotspot openj9"

# All supported arches
all_arches="aarch64 ppc64le s390x x86_64"

# Current JVM versions supported
export supported_versions="8 9 10"

# Current builds supported
export supported_builds="releases nightly"

function check_version() {
	version=$1
	case ${version} in
	8|9|10)
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
		arch="aarch64"
		oses="ubuntu"
		package="jdk"
		;;
	ppc64el|ppc64le)
		arch="ppc64le"
		oses="ubuntu"
		package="jdk"
		;;
	s390x)
		arch="s390x"
		oses="ubuntu"
		package="jdk"
		;;
	amd64|x86_64)
		arch="x86_64"
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
	# Eg. jdk_openj9_10_release_sums does not exist as we do not have any
	# release builds for version 10 (Only nightly builds).
	declare -p $1 >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		return;
	fi
	archsums="$(declare -p $1)";
	eval "declare -A sums="${archsums#*=};
	for arch in ${!sums[@]};
	do
		if [ "${arch}" != "version" ]; then
			echo "${arch} "
		fi
	done
}

# Check if the given VM is supported on the current architecture.
# This is based on the hotspot_shasums_latest.sh/openj9_shasums_latest.sh
function vm_supported_onarch() {
	vm=$1
	sums=$2
	currarch=`uname -m`

	suparches=$(get_arches ${sums})
	sup=$(echo ${suparches} | grep ${currarch})
	echo ${sup}
}

function cleanup_images() {
	# Delete any old containers that have exited.
	docker rm $(docker ps -a | grep "Exited" | awk '{ print $1 }') 2>/dev/null

	# Delete any old images for our target_repo on localhost.
	docker rmi -f $(docker images | grep -e "${target_repo}" | awk '{ print $3 }' | sort | uniq) 2>/dev/null
}

function cleanup_manifest() {
	# Remove any previously created manifest lists.
	# Currently there is no way to do this using the tool.
	rm -rf ~/.docker/manifests
}

# Parse the openj9.config / hotspot.config file for an entry as specified by $4
# $1 = VM
# $2 = Version
# $3 = OS
# $4 = String to look for.
function parse_vm_entry() {
	entry=$(cat ${1}.config | grep -B 4 "$2\/.*\/$3" | grep "$4" | sed "s/$4 //")
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
