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

# Current JVM versions supported
export supported_versions="8 9 10"

# Current build types supported
export build_types="releases nightly"

function check_version()
{
	case $version in
	8|9|10)
		;;
	*)
		echo "ERROR: Invalid version"
		;;
	esac
}

# Get the supported architectures for a given VM (Hotspot, OpenJ9).
# This is based on the hotspot_shasums_latest.sh/openj9_shasums_latest.sh
function get_arches() {
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
