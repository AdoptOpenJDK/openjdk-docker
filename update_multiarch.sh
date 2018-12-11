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
set -eo pipefail

# Dockerfiles to be generated
version="9"
package="jdk"
osver="ubuntu alpine"

source ./common_functions.sh

if [ ! -z "$1" ]; then
	set_version $1
fi
	
# Which JVMs are available for the current version
./generate_latest_sums.sh ${version}

# Source the hotspot and openj9 shasums scripts
available_jvms=""
if [ -f hotspot_shasums_latest.sh ]; then
	source ./hotspot_shasums_latest.sh
	available_jvms="hotspot"
fi
if [ -f openj9_shasums_latest.sh ]; then
	source ./openj9_shasums_latest.sh
	available_jvms="${available_jvms} openj9"
fi

# Iterate through all the Java versions for each of the supported packages,
# architectures and supported Operating Systems.
for vm in ${available_jvms}
do
	oses=$(parse_os_entry ${vm})
	for os in ${oses}
	do
		# Build = Release or Nightly
		builds=$(parse_vm_entry ${vm} ${version} ${os} "Build:")
		# Build Type = Full or Slim
		btypes=$(parse_vm_entry ${vm} ${version} ${os} "Type:")
		dir=$(parse_vm_entry ${vm} ${version} ${os} "Directory:")

		for build in ${builds}
		do
			shasums="${package}"_"${vm}"_"${version}"_"${build}"_sums
			jverinfo=${shasums}[version]
			eval jver=\${$jverinfo}
			if [[ -z ${jver} ]]; then
				continue;
			fi
			for btype in ${btypes}
			do
				file=${dir}/Dockerfile.${vm}.${build}.${btype}
				# Copy the script to generate slim builds.
				if [ "${btype}" = "slim" ]; then
					cp slim-java* config/slim-java* ${dir}
				fi
				reldir="openjdk${version}";
				if [ "${vm}" != "hotspot" ]; then
					reldir="${reldir}-${vm}";
				fi
				generate_dockerfile ${file} ${build} ${btype} ${os}
			done
		done
	done
done
