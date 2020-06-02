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
# image github repo and the doc updates for the unofficial docker image repo.
# Process to update the official docker image repo 
# 1. Run ./update_all.sh to update all the dockerfiles in the current repo.
# 2. Submit PR to push the newly generated dockerfiles to the current repo.
# 3. After above PR is merged, git pull the latest changes.
# 4. Run this command
#
set -o pipefail

# shellcheck source=common_functions.sh
source ./common_functions.sh

official_docker_image_file="adoptopenjdk"
oses="alpine centos clefos debian debianslim ubi ubi-minimal ubuntu"

# shellcheck disable=SC2034 # used externally
hotspot_latest_tags="hotspot, latest"
# shellcheck disable=SC2034 # used externally
openj9_latest_tags="openj9"

git_repo="https://github.com/AdoptOpenJDK/openjdk-docker/blob/master"

# Get the latest git commit of the current repo.
# This is assumed to have all the latest dockerfiles already.
gitcommit=$(git log | head -1 | awk '{ print $2 }')

print_official_text() {
	echo "$*" >> ${official_docker_image_file}
}

print_unofficial_tags() {
	for tag in "$@"
	do
		echo -n "\`${tag}\`, " >>  "${ver}"_"${vm}".txt
	done
}

print_official_header() {
	print_official_text "# AdoptOpenJDK official images for OpenJDK with HotSpot and OpenJDK with Eclipse OpenJ9."
	print_official_text
	print_official_text "Maintainers: Dinakar Guniguntala <dinakar.g@in.ibm.com> (@dinogun)"
	print_official_text "GitRepo: https://github.com/AdoptOpenJDK/openjdk-docker.git"
}

function generate_unofficial_image_info() {
	full_version=$(grep "VERSION" "${file}" | awk '{ print $3 }')
	# Replace "+" with "_" in the version info as docker does not support "+"
	full_version=${full_version//+/_}

	# Build a list of super tags (in addition to the non arch specific tags)
	super_tags="";
	case ${os} in
	ubuntu)
		attrs=""
		# JRE ubuntu builds have a `jre` tag
		if [ "${pkg}" == "jre" ]; then
			super_tags="${pkg}";
			full_version=${full_version//jdk/jre}
		fi
		# Nightly ubuntu builds have a `nightly` tag
		if [ "${build}" == "nightly" ]; then
			if [ "${super_tags}" == "" ]; then
				super_tags="${build}";
			else
				super_tags="${super_tags}-${build}"
			fi
			attrs="${build}"
		fi
		# Slim ubuntu builds have a `slim` tag
		if [ "${btype}" == "slim" ]; then
			if [ "${super_tags}" == "" ]; then
				super_tags="${btype}"
			else
				super_tags="${super_tags}-${btype}"
			fi
			if [ "${attrs}" == "" ]; then
				attrs="${btype}"
			else
				attrs="${attrs}-${btype}"
			fi
		fi
		# If none of the above, it has to be the `latest` build
		if [ "${super_tags}" == "" ]; then
			super_tags="latest";
		fi
		super_tags="${super_tags} ${full_version}";
		if [ "${attrs}" == "" ]; then
			vattrs="${full_version}"
		fi
		;;
	alpine|centos|clefos|debian|debianslim|ubi|ubi-minimal|windows)
		# Non Ubuntu builds all have the `$os` tag prepended
		super_tags="${os}";
		attrs=""
		if [ "${pkg}" == "jre" ]; then
			super_tags="${super_tags}-${pkg}";
			attrs="${pkg}"
			full_version=${full_version//jdk/jre}
		fi
		if [ "${build}" == "nightly" ]; then
			super_tags="${super_tags}-${build}";
			attrs="${build}"
		fi
		if [ "${btype}" == "slim" ]; then
			super_tags="${super_tags}-${btype}"
			if [ "${attrs}" == "" ]; then
				attrs="${btype}"
			else
				attrs="${attrs}-${btype}"
			fi
		fi
		if [ "${attrs}" == "" ]; then
			super_tags="${super_tags} ${full_version}-${os}"
			vattrs="${full_version}"
		fi
		;;
	esac
	if [ -n "${attrs}" ]; then
		super_tags="${super_tags} ${full_version}-${os}-${attrs}"
		vattrs="${full_version}-${attrs}"
	fi

	# Unofficial images support x86_64, aarch64, s390x and ppc64le
	# Remove ppc64el, amd64 and arm64
	# Retain ppc64le, x86_64 and aarch64
	# shellcheck disable=SC2046,SC2005,SC1003,SC2086,SC2063 # TODO need to rewrite this
	arches=$(echo $(grep ') \\' ${file} | sed 's/\(ppc64el\|amd64\|arm64\|armhf\)//g' | sort | grep -v "*" | sed 's/) \\//g; s/|/ /g'))
	if [ "${os}" == "alpine" ]; then
		# Alpine builds are only available for x86_64 currently
		arches="x86_64"
	elif [ "${os}" == "centos" ]; then
		arches=${arches//s390x/}
	elif [ "${os}" == "clefos" ]; then
		arches="s390x"
	elif [[ "${os}" =~ "ubi" ]]; then
		arches=${arches//armv7l/}
	fi
	# shellcheck disable=SC2086
	print_unofficial_tags ${super_tags}
	for arch in ${arches}
	do
		print_unofficial_tags "${arch}-${os}-${vattrs}" >> "${ver}"_"${vm}".txt
	done
	# Remove the leading "./" from the file name
	file=$(echo "${file}" | cut -c 3-)
	echo "(*${file}*)](${git_repo}/${file})" >> "${ver}"_"${vm}".txt
}

function generate_official_image_tags() {
	# Generate the tags
	full_version=$(grep "VERSION" "${file}" | awk '{ print $3 }')

	# Remove any `jdk` references in the version
	ojdk_version=$(echo "${full_version}" | sed 's/\(jdk\|jdk-\)//' | awk -F '_' '{ print $1 }')
	# Replace "+" with "_" in the version info as docker does not support "+"
	ojdk_version=${ojdk_version//+/_}

	# Official image build tags are as below
	# 8u212-jre-openj9_0.12.1
	# 8-jre-openj9
	# 8u212-jdk-hotspot
	full_ver_tag="${ojdk_version}-${pkg}"
	# Add the openj9 version
	if [ "${vm}" == "openj9" ]; then
		openj9_version=$(echo "${full_version}" | awk -F '_' '{ print $2 }')
		full_ver_tag="${full_ver_tag}-${openj9_version}"
	else
		full_ver_tag="${full_ver_tag}-${vm}"
	fi
		ver_tag="${ver}-${pkg}-${vm}"
	all_tags="${full_ver_tag}, ${ver_tag}"
	# jdk builds also have additional tags
	if [ "${pkg}" == "jdk" ]; then
		jdk_tag="${ver}-${vm}"
		all_tags="${all_tags}, ${jdk_tag}"
		# Add the "latest", "hotspot" and "openj9" tags for the right version
		if [ "${ver}" == "${latest_version}" ]; then
			vm_tags="${vm}_latest_tags"
			# shellcheck disable=SC1083,SC2086
			eval vm_tags_val=\${$vm_tags}
			# shellcheck disable=SC2154
			all_tags="${all_tags}, ${vm_tags_val}"
		fi
	fi
}

function generate_official_image_arches() {
	# Generate the supported arches for the above tags.
	# Official images supports amd64, arm64vX, s390x and ppc64le
	# Remove ppc64el, x86_64 and aarch64
	# Retain ppc64le, amd64 and arm64
	# armhf is arm32v7 and arm64 is arm64v8 for docker builds
	# shellcheck disable=SC2046,SC2005,SC1003,SC2086,SC2063 # TODO need to rewrite this
	arches=$(echo $(grep ') \\' ${file} | sed 's/\(ppc64el\|x86_64\|aarch64\)//g' | sed 's/armhf/arm32v7/' | sed 's/arm64/arm64v8/' | sort | grep -v "*" | sed 's/) \\//g; s/|/ /g'))
	# Add a "," after each arch
	arches=${arches// /, }
}

function print_official_image_file() {
	# Print them all
	{
	  echo "Tags: ${all_tags}"
	  echo "Architectures: ${arches}"
	  echo "GitCommit: ${gitcommit}"
	  echo "Directory: ${dfdir}"
	  echo "File: ${dfname}"
	} >> ${official_docker_image_file}
}

rm -f ${official_docker_image_file}
print_official_header

# Currently we are not pushing official docker images for Alpine, Debian and Windows
official_os_ignore_array=(alpine debian ubi-minimal)

# Generate config and doc info only for "supported" official builds.
function generate_official_image_info() {
	# If it is an unsupported OS from the array above, return.
	for arr_os in "${official_os_ignore_array[@]}"; 
	do
		if [ "${os}" == "${arr_os}" ]; then
			return;
		fi
	done	
	# We do not push our nightly and slim images either.
	if [ "${build}" == "nightly" ] || [ "${btype}" == "slim" ]; then
		return;
	fi

	generate_official_image_tags
	generate_official_image_arches
	print_official_image_file
}

# Iterate through all the VMs, for each supported version and packages to
# generate the config file for the official docker images.
# Official docker images = https://hub.docker.com/_/adoptopenjdk
for vm in ${all_jvms}
do
	for ver in ${supported_versions}
	do
		print_official_text
		print_official_text "#------------------------------${vm} v${ver} images-------------------------------"
		for pkg in ${all_packages}
		do
			print_official_text
			# Iterate through each of the Dockerfiles.
			for file in $(find . -name "Dockerfile.*" | grep "/${ver}" | grep "${vm}" | grep "${pkg}")
			do
				# file will look like ./12/jdk/debian/Dockerfile.openj9.nightly.slim
				# dockerfile name
				dfname=$(basename "${file}")
				# dockerfile dir
				dfdir=$(dirname : | cut -c 3-)
				os=$(echo "${file}" | awk -F '/' '{ print $4 }')
				# build = release or nightly
				build=$(echo "${dfname}" | awk -F "." '{ print $3 }')
				# btype = full or slim
				btype=$(echo "${dfname}" | awk -F "." '{ print $4 }')

				generate_official_image_info
			done
		done
	done
done

# This loop generated the documentation for the unofficial docker images
# Unofficial docker images = https://hub.docker.com/r/adoptopenjdk
for vm in ${all_jvms}
do
	for ver in ${supported_versions}
	do
		# Remove any previous doc files
		rm -f "${ver}"_"${vm}".txt
		for build in ${supported_builds}
		do
			if [ "${build}" == "releases" ]; then
				echo "**Release Builds**" >> "${ver}"_"${vm}".txt
			else
				echo "**Nightly Builds**" >> "${ver}"_"${vm}".txt
			fi
			for os in ${oses}
			do
				for pkg in ${all_packages}
				do
					for file in $(find . -name "Dockerfile.*" | grep "/${ver}" | grep "${vm}" | grep "${build}" | grep "/${os}/" | grep "${pkg}")
					do
						echo -n "- [" >> "${ver}"_"${vm}".txt
						dfname=$(basename "${file}")
						# dockerfile dir
						dfdir=$(dirname "${file}" | cut -c 3-)
						pkg=$(echo "${file}" | awk -F '/' '{ print $3 }')
						os=$(echo "${file}" | awk -F '/' '{ print $4 }')
						# build = release or nightly
						build=$(echo "${dfname}" | awk -F "." '{ print $3 }')
						# btype = full or slim
						btype=$(echo "${dfname}" | awk -F "." '{ print $4 }')

						generate_unofficial_image_info
					done
				done
				echo >> "${ver}"_"${vm}".txt
			done
			echo >> "${ver}"_"${vm}".txt
		done
	done
done
