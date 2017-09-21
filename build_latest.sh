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
set -eo pipefail

root_dir="$PWD"
target_repo="adoptopenjdk/openjdk"

# Find the latest version and get the corresponding shasums
./generate_latest_sums.sh

source ./hotspot-shasums-latest.sh
source ./openj9-shasums-latest.sh

# Generate the Dockerfiles for the latest version
./update-multiarch.sh

# Build the docker images and tag it based on the arch that we are on currently
machine=`uname -m`
case $machine in
aarch64)
	arch="aarch64"
	oses="ubuntu"
	package="jdk"
	version="9"
	vms="hotspot"
	;;
ppc64le)
	arch="ppc64le"
	oses="ubuntu"
	package="jdk"
	version="9"
	vms="hotspot openj9"
	;;
s390x)
	arch="s390x"
	oses="ubuntu"
	package="jdk"
	version="9"
	vms="hotspot openj9"
	;;
x86_64)
	arch="x86_64"
	oses="ubuntu alpine"
	package="jdk"
	version="9"
	vms="hotspot openj9"
	;;
*)
	echo "Unsupported arch:$machine, Exiting"
	exit 1
	;;
esac

function build_image() {
	repo=$1
	shift

	tags=""
	for tag in $*
	do
		tags="${tags} -t ${repo}:${tag}"
	done

	docker build --no-cache ${tags} -f Dockerfile.${vm} . 
}

# Delete any old images for our target_repo on localhost
docker rmi -f $(docker images | grep -e "${target_repo}" | awk '{ print $3 }' | sort | uniq) 2>/dev/null

# Valid image tags
#adoptopenjdk/openjdk${version}:${arch}-${rel}
#adoptopenjdk/openjdk${version}:${arch}-${os}-${rel}
#adoptopenjdk/openjdk${version}:${rel}
#adoptopenjdk/openjdk${version}:latest

#adoptopenjdk/openjdk${version}-openj9:${arch}-${rel}
#adoptopenjdk/openjdk${version}-openj9:${arch}-${os}-${rel}
#adoptopenjdk/openjdk${version}-openj9:${rel}
#adoptopenjdk/openjdk${version}-openj9:latest
#
for os in ${oses}
do
	for vm in ${vms}
	do
		shasums="${package}"_"${vm}"_"${version}"_sums
		jverinfo=${shasums}[version]
		eval jrel=\${$jverinfo}
		rel=$(echo $jrel | sed 's/+/./')
	
		file="${root_dir}/${version}/${package}/${os}/Dockerfile.${vm}"
		if [ ! -f $file ]; then
			continue;
		fi
		ddir=`dirname $file`
		pushd $ddir >/dev/null
		if [ "${vm}" == "hotspot" ]; then
			trepo=${target_repo}${version}
		else
			trepo=${target_repo}${version}-${vm}
		fi
		if [ "${os}" != "ubuntu" ]; then
			tag=${arch}-${os}-${rel}
			echo "Building ${trepo} ${tag} from $file ..."
			build_image ${trepo} ${tag}
		else
			tag=${arch}-${rel}
			echo "Building ${trepo} ${tag} ${rel} latest from $file ..."
			build_image ${trepo} ${tag} ${rel} latest
		fi
		popd >/dev/null
	done
done
