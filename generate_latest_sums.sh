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
jvms="hotspot openj9"
arches="aarch64 ppc64le s390x x86_64"
rootdir="$PWD"

source ./common_functions.sh

if [ ! -z "$1" ]; then
	version=$1
	if [ ! -z "$(check_version $version)" ]; then
		echo "ERROR: Invalid Version"
		echo "Usage: $0 [${supported_versions}]"
		exit 1
	fi
fi

function get_shasums() {
	ver=$1
	vm=$2
	ofile="${rootdir}/${vm}_shasums_latest.sh"

	if [ "$vm" == "openj9" ]; then
		reldir="openjdk${ver}-openj9"
	else
		reldir="openjdk${ver}"
	fi
	info_url="https://api.adoptopenjdk.net/${reldir}/releases/x64_linux/latest"
	info=$(curl -Ls ${info_url})
	err=$(echo ${info} | grep -e "Error" -e "No matches")
	if [ "${err}" != ""  ]; then
		return;
	fi
	full_version=$(echo ${info} | grep "release_name" | awk -F'"' '{ print $4 }');
	printf "declare -A jdk_%s_%s_sums=(\n" $vm $ver > ${ofile}
	printf "\t[version]=\"%s\"\n" ${full_version} >> ${ofile}
	for arch in ${arches}
	do
		case ${arch} in
		aarch64)
			LATEST_URL="https://api.adoptopenjdk.net/${reldir}/releases/aarch64_linux/latest";
			;;
		ppc64le)
			LATEST_URL="https://api.adoptopenjdk.net/${reldir}/releases/ppc64le_linux/latest";
			;;
		s390x)
			LATEST_URL="https://api.adoptopenjdk.net/${reldir}/releases/s390x_linux/latest";
			;;
		x86_64)
			LATEST_URL="https://api.adoptopenjdk.net/${reldir}/releases/x64_linux/latest";
			;;
		*)
			echo "Unsupported arch: ${arch}"
		esac
		curl -Lso ${arch}_latest ${LATEST_URL};
		availability=$(grep "No matches" ${arch}_latest);
		if [ -z "${availability}" ]; then
			shasums_url=$(cat ${arch}_latest | grep "checksum_link" | awk -F'"' '{ print $4 }');
			shasum=$(curl -Ls ${shasums_url} | sed -e 's/<[^>]*>//g' | awk '{ print $1 }');
			printf "\t[%s]=\"%s\"\n" ${arch} ${shasum} >> ${ofile}
		fi
		rm -f ${arch}_latest
	done
	printf ")\n" >> ${ofile}
	chmod +x ${ofile}

	echo
	echo "sha256sums for the version: ${full_version} now available in ${ofile}"
	echo
}


echo "Getting latest shasum info for major version: $version"
for ver in ${version}
do
	for vm in ${jvms}
	do
		get_shasums ${ver} ${vm}
	done
done
