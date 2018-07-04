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
set -o pipefail

version="9"
rootdir="$PWD"

source ./common_functions.sh

function get_shasums() {
	ver=$1
	vm=$2
	ofile="${rootdir}/${vm}_shasums_latest.sh"

	reldir="openjdk${ver}"
	if [ "${vm}" != "hotspot" ]; then
		reldir="${reldir}-${vm}"
	fi
	for build in ${supported_builds}
	do
		info_url="https://api.adoptopenjdk.net/${reldir}/${build}/x64_linux/latest"
		# Repeated requests from a script triggers a error threshold on adoptopenjdk.net
		sleep 1;
		info=$(curl -Ls ${info_url})
		err=$(echo ${info} | grep -e "Error" -e "No matches")
		if [ ! -z "${err}" ]; then
			continue;
		fi
		full_version=$(echo ${info} | grep "release_name" | awk -F'"' '{ print $4 }');
		if [ "${build}" == "nightly" ]; then
			# Remove date and time at the end of full_version for nightly builds.
			full_version=$(echo ${full_version} | sed 's/-[0-9]\{4\}[0-9]\{2\}[0-9]\{2\}[0-9]\{4\}$//')
		fi
		# Declare the array with the proper name and write to the vm output file.
		printf "declare -A jdk_%s_%s_%s_sums=(\n" ${vm} ${ver} ${build} >> ${ofile}
		# Capture the full version according to adoptopenjdk
		printf "\t[version]=\"%s\"\n" ${full_version} >> ${ofile}
		for arch in ${all_arches}
		do
			case ${arch} in
			aarch64)
				LATEST_URL="https://api.adoptopenjdk.net/${reldir}/${build}/aarch64_linux/latest";
				;;
			ppc64le)
				LATEST_URL="https://api.adoptopenjdk.net/${reldir}/${build}/ppc64le_linux/latest";
				;;
			s390x)
				LATEST_URL="https://api.adoptopenjdk.net/${reldir}/${build}/s390x_linux/latest";
				;;
			x86_64)
				LATEST_URL="https://api.adoptopenjdk.net/${reldir}/${build}/x64_linux/latest";
				;;
			*)
				echo "Unsupported arch: ${arch}"
			esac
			shasum_file="${arch}_${build}_latest"
			curl -Lso ${shasum_file} ${LATEST_URL};
			availability=$(grep "No matches" ${shasum_file});
			# Print the arch and the corresponding shasums to the vm output file
			if [ -z "${availability}" ]; then
				# If there are multiple builds for a single version, then pick the latest one.
				shasums_url=$(cat ${shasum_file} | grep "checksum_link" | head -1 | awk -F'"' '{ print $4 }');
				shasum=$(curl -Ls ${shasums_url} | sed -e 's/<[^>]*>//g' | awk '{ print $1 }');
				printf "\t[%s]=\"%s\"\n" ${arch} ${shasum} >> ${ofile}
			fi
			rm -f ${shasum_file}
		done
		printf ")\n" >> ${ofile}

		echo
		echo "sha256sums for the version ${full_version} for build type \"${build}\" is now available in ${ofile}"
		echo
	done
	chmod +x ${ofile}
}

if [ ! -z "$1" ]; then
	set_version $1
fi

echo "Getting latest shasum info for major version: ${version}"
for vm in ${all_jvms}
do
	get_shasums ${version} ${vm}
done
