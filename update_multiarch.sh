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

# Dockerfiles to be generated
version="9"
export root_dir="$PWD"

source ./common_functions.sh
source ./dockerfile_functions.sh

if [ -n "$1" ]; then
	set_version "$1"
fi

# Set the OSes that will be built on based on the current arch
set_arch_os

# Iterate through all the Java versions for each of the supported packages,
# architectures and supported Operating Systems.
for vm in ${all_jvms}
do
	for package in ${all_packages}
	do
		oses=$(parse_os_entry "${vm}")
		for os in ${oses}
		do
			# Build = Release or Nightly
			builds=$(parse_vm_entry "${vm}" "${version}" "${package}" "${os}" "Build:")
			# Build Type = Full or Slim
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
				else
					continue;
				fi
				# Check if the VM is supported for the current arch
				shasums="${package}"_"${vm}"_"${version}"_"${build}"_sums
				sup=$(vm_supported_onarch "${vm}" "${shasums}")
				if [ -z "${sup}" ]; then
					continue;
				fi
				# Generate all the Dockerfiles for each of the builds and build types
				for btype in ${btypes}
				do
					file="${dir}/Dockerfile.${vm}.${build}.${btype}"
					generate_dockerfile "${file}" "${package}" "${build}" "${btype}" "${osfamily}" "${os}"
					# Copy the script to generate slim builds.
					if [ "${btype}" = "slim" ]; then
						if [ "${os}" == "windows" ]; then
							cp slim-java.ps1 config/slim-java* "${dir}"
						else
							cp slim-java.sh config/slim-java* "${dir}"
						fi
					fi
				done
			done
		done
	done
done
