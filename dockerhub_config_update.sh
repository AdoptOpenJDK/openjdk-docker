#!/bin/bash
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
# Script that generates the `adoptopenjdk` config file for the official docker
# image github repo.
# Process to update the official docker image repo 
# 1. Run ./update_all.sh to update all the dockerfiles in the current repo.
# 2. Submit PR to push the newly generated dockerfiles to the current repo.
# 3. After above PR is merged, git pull the latest changes.
# 4. Run this command
#
set -o pipefail

source ./common_functions.sh

latest_version="12"
hotspot_latest_tags="hotspot, latest"
openj9_latest_tags="openj9"

# Get the latest git commit of the current repo.
# This is assumed to have all the latest dockerfiles already.
gitcommit=$(git log | head -1 | awk '{ print $2 }')

echo "# AdoptOpenJDK official images for OpenJDK with HotSpot and OpenJDK with Eclipse OpenJ9."
echo
echo "Maintainers: Dinakar Guniguntala <dinakar.g@in.ibm.com> (@dinogun)"
echo "GitRepo: https://github.com/AdoptOpenJDK/openjdk-docker.git"

# Iterate through all the VMs, for each supported version and packages to
# generate the config file.
for vm in ${all_jvms}
do
	for ver in ${supported_versions}
	do
		echo
		echo "#------------------------------${vm} v${ver} images-------------------------------"
		for pkg in ${all_packages}
		do
			echo
			# Iterate through each of the Dockerfiles.
			for file in $(find . -name "Dockerfile.*" | grep "/${ver}" | grep "${vm}" | grep "${pkg}")
			do
				# file will look like ./12/jdk/debian/Dockerfile.openj9.nightly.slim
				# dockerfile name
				dfname=$(basename ${file})
				# dockerfile dir
				dfdir=$(dirname ${file} | cut -c 3-)
				os=$(echo ${file} | awk -F '/' '{ print $4 }')
				# build = release or nightly
				build=$(echo ${dfname} | awk -F "." '{ print $3 }')
				# btype = full or slim
				btype=$(echo ${dfname} | awk -F "." '{ print $4 }')

				# Currently we are not pushing docker images for Alpine, Debian and Windows
				if [ "${os}" == "windows" -o "${os}" == "alpine" -o "${os}" == "debian" ]; then
					continue;
				fi

				# We do not push our nightly and slim images either.
				if [ "${build}" == "nightly" -o "${btype}" == "slim" ]; then
					continue;
				fi

				# Generate the tags
				full_version=$(grep "VERSION" ${file} | awk '{ print $3 }')
				ojdk_version=$(echo ${full_version} | sed 's/\(jdk\|jdk-\)//' | awk -F '_' '{ print $1 }')
				ojdk_version=$(echo ${ojdk_version} | sed 's/+/_/')

				full_ver_tag="${ojdk_version}-${pkg}"
				# Add the openj9 version
				if [ "${vm}" == "openj9" ]; then
					openj9_version=$(echo ${full_version} | awk -F '_' '{ print $2 }')
					full_ver_tag="${full_ver_tag}-${openj9_version}"
				else
					full_ver_tag="${full_ver_tag}-${vm}"
				fi
				ver_tag="${ver}-${pkg}-${vm}"
				all_tags="${full_ver_tag}, ${ver_tag}"
				if [ "${pkg}" == "jdk" ]; then
					jdk_tag="${ver}-${vm}"
					all_tags="${all_tags}, ${jdk_tag}"
					# Add the "latest", "hotspot" and "openj9" tags for the right version
					if [ "${ver}" == "${latest_version}" ]; then
						vm_tags="${vm}_latest_tags"
						eval vm_tags_val=\${$vm_tags}
						all_tags="${all_tags}, ${vm_tags_val}"
					fi
				fi

				# Generate the supported arches for the above tags.
				arches=$(echo $(grep ') \\' ${file} | \
					sed 's/\(ppc64el\|x86_64\|aarch64\)//g' | \
					sed 's/armhf/arm32v7/' | \
					sed 's/arm64/arm64v8/' | \
					sort | grep -v "*" | \
					sed 's/) \\//g; s/|/ /g'))
				arches=$(echo ${arches} | sed 's/ /, /g')

				# Print them all
				echo "Tags: ${all_tags}"
				echo "Architectures: ${arches}"
				echo "GitCommit: ${gitcommit}"
				echo "Directory: ${dfdir}"
				echo "File: ${dfname}"
			done
		done
	done
done
