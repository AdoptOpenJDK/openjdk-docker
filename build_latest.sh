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

root_dir="$PWD"
push_cmdfile=${root_dir}/push_commands.sh
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
	echo "ERROR: Unsupported arch:$machine, Exiting"
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
		echo "docker push ${repo}:${tag}" >> ${push_cmdfile}
	done

	echo "#####################################################"
	echo "INFO: docker build --no-cache ${tags} -f Dockerfile.${vm} ."
	echo "#####################################################"
	docker build --no-cache ${tags} -f Dockerfile.${vm} . 
}

# Delete any old images for our target_repo on localhost
docker rmi -f $(docker images | grep -e "${target_repo}" | awk '{ print $3 }' | sort | uniq) 2>/dev/null

# Script that has the push commands for the images that we are building.
echo "#!/bin/bash" > ${push_cmdfile}
echo >> ${push_cmdfile}

# Valid image tags
#adoptopenjdk/openjdk${version}:${arch}-${os}-${rel}
#adoptopenjdk/openjdk${version}-openj9:${arch}-${os}-${rel}
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
		tag=${arch}-${os}-${rel}
		echo "INFO: Building ${trepo} ${tag} from $file ..."
		build_image ${trepo} ${tag}
		popd >/dev/null
	done
done
chmod +x ${push_cmdfile}

echo
echo "INFO: The push commands are available in file ${push_cmdfile}"
