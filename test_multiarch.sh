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

export root_dir="$PWD"
source_prefix=${ADOPTOPENJDK_TARGET_REGISTRY:-adoptopenjdk}
source_repo="openjdk"
version="9"
tag_aliases=""
arch_tags=""

# shellcheck source=common_functions.sh
source ./common_functions.sh

if [ $# -ne 3 ]; then
	echo
	echo "usage: $0 version vm package"
	echo "version = ${supported_versions}"
	echo "vm      = ${all_jvms}"
	echo "package = ${all_packages}"
	exit 1
fi

set_version "$1"
vm=$2
package=$3

# Run a java -version test for a given docker image.
function test_java_version() {
	local img=$1
	local rel=$2

	echo
	echo "TEST: Running java -version test on image: ${img}..."
	# Don't use "-it" flags as the jenkins job doesn't have a tty
	if ! docker run --rm "${img}" java -version; then
		printf "\n##############################################\n"
		printf "\nERROR: Docker Image %s failed the java -version test\n" "${img}"
		printf "\n##############################################\n"
	fi
	echo
}

# Run all test buckets for the given image.
function run_tests() {
	local img=$1
	local rel=$2

	grep -v '^#' < "${test_buckets_file}" | while IFS= read -r test_case
	do
		${test_case} "${img}" "${rel}"
	done
}

# Run tests on all the alias docker tags.
function test_aliases() {
	local repo=$1
	local rel=$2
	local target_repo=${source_prefix}/${repo}

	# Check if all the individual docker images exist for each expected arch
	for arch_tag in ${arch_tags}
	do
		echo -n "INFO: Pulling image: ${target_repo}:${arch_tag}..."
		ret=$(check_image "${target_repo}":"${arch_tag}")
		if [ "${ret}" != 0 ]; then
			printf "\n##############################################\n"
			printf "\nError: Docker Image %s not found on hub.docker\n" "${img}"
			printf "\n##############################################\n"
		fi
	done

	# Global variable tag_aliases has the alias list
	for tag_alias in ${tag_aliases}
	do
		echo -n "INFO: Pulling image: ${target_repo}:${tag_alias}..."
		ret=$(check_image "${target_repo}":"${tag_alias}")
		if [ "${ret}" != 0 ]; then
			printf "\n##############################################\n"
			printf "\nError: Docker Image %s not found on hub.docker\n" "${img}"
			printf "\n##############################################\n"
		fi
		run_tests "${target_repo}":"${tag_alias}" "${rel}"
	done
}

# Check each of the images in the global variable arch_tags exist
# and run tests on them
function test_tags() {
	local repo=$1
	local rel=$2
	local target_repo=${source_prefix}/${repo}

	# Check if all the individual docker images exist for each expected arch
	for arch_tag in ${arch_tags}
	do
		tarch=$(echo "${arch_tag}" | awk -F"-" '{ print $1 }')
		if [ "${tarch}" != "${current_arch}" ]; then
			continue;
		fi
		echo -n "INFO: Pulling image: ${target_repo}:${arch_tag}..."
		ret=$(check_image "${target_repo}":"${arch_tag}")
		if [ "${ret}" != 0 ]; then
			printf "\n##############################################\n"
			printf "\nError: Docker Image %s not found on hub.docker\n" "${img}"
			printf "\n##############################################\n"
		fi
		run_tests "${target_repo}":"${arch_tag}" "${rel}"
	done
}

# Run tests for each of the test image types
# Currently image types = test_tags and test_aliases.
function test_image_types() {
	local srepo=$1
	local rel=$2

	grep -v '^#' "${test_image_types_file}" | while IFS= read -r test_image
	do
		${test_image} "${srepo}" "${rel}"
	done
}

# Set the OSes that will be built on based on the current arch
set_arch_os

# Which JVMs are available for the current version
./generate_latest_sums.sh "${version}"

# Source the hotspot and openj9 shasums scripts
available_jvms=""
if [ "${vm}" == "hotspot" ] && [ -f hotspot_shasums_latest.sh ]; then
	# shellcheck disable=SC1091
	source ./hotspot_shasums_latest.sh
	available_jvms="hotspot"
fi
if [ "${vm}" == "openj9" ] && [ -f openj9_shasums_latest.sh ]; then
	# shellcheck disable=SC1091
	source ./openj9_shasums_latest.sh
	available_jvms="${available_jvms} openj9"
fi

# Go through each vm / os / build / type combination and build the manifest commands
# vm    = hotspot / openj9
# os    = alpine / ubuntu
# build = releases / nightly
# type  = full / slim
for os in ${oses}
do
	builds=$(parse_vm_entry "${vm}" "${version}" "${package}" "${os}" "Build:")
	btypes=$(parse_vm_entry "${vm}" "${version}" "${package}" "${os}" "Type:")
	for build in ${builds}
	do
		shasums="${package}"_"${vm}"_"${version}"_"${build}"_sums
		jverinfo="${shasums}[version]"
		# shellcheck disable=SC1083,SC2086
		eval jrel=\${$jverinfo}
		# shellcheck disable=SC2154
		if [[ -z "${jrel}" ]]; then
			continue;
		fi
		# Docker image tags cannot have "+" in them, replace it with "_" instead.
		rel=${jrel//+/_}

		srepo=${source_repo}${version}
		if [ "${vm}" != "hotspot" ]; then
			srepo=${srepo}-${vm}
		fi
		for btype in ${btypes}
		do
			echo -n "INFO: Building tag list for [${vm}]-[${os}]-[${build}]-[${btype}]..."
			# Get the relevant tags for this vm / os / build / type combo from the tags.config file.
			raw_tags=$(parse_tag_entry "${os}" "${package}" "${build}" "${btype}")
			# Build tags will build both the arch specific tags and the tag aliases.
			build_tags "${vm}" "${version}" "${package}" "${rel}" "${os}" "${build}" "${raw_tags}"
			echo "done"
			# Test both the arch specific tags and the tag aliases.
			test_image_types "${srepo}" "${rel}"
		done
	done
done

echo "INFO: Test complete"
