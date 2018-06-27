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
source_prefix="adoptopenjdk"
source_repo="openjdk"
version="9"
tag_aliases=""
arch_tags=""
man_file=${root_dir}/manifest_commands.sh

source ./common_functions.sh

# Check if a given docker image exists on the server.
# This script errors out if the image does not exist.
function check_image() {
	img=$1

	echo -n "INFO: Pulling image: ${img}..."
	docker pull ${img} >/dev/null
	if [ $? != 0 ]; then
		echo "ERROR: Docker Image ${img} not found on hub.docker\n"
		exit 1
	fi
	echo "done"
}

# Print the arch specific annotate command.
function print_annotate_cmd() {
	main_tag=$1
	arch_tag=$2

	# The manifest tool expects "amd64" as arch and not "x86_64"
	march=$(echo ${arch_tag} | awk -F':' '{ print $2 }' | awk -F'-' '{ print $1 }')
	if [ ${march} == "x86_64" ]; then
		march="amd64"
	fi
	echo "${manifest_tool} manifest annotate ${main_tag} ${arch_tag} --os linux --arch ${march}" >> ${man_file}
}

# Space separated list of tags
function print_manifest_cmd() {
	trepo=$1; shift;
	img_list=$*

	# Global variable tag_aliases has the alias list
	for talias in ${tag_aliases}
	do
		echo "${manifest_tool} manifest create ${trepo}:${talias} ${img_list}" >> ${man_file}
		for img in ${img_list}
		do
			print_annotate_cmd ${trepo}:${talias} ${img}
		done
		echo "${manifest_tool} manifest push ${trepo}:${talias}" >> ${man_file}
		echo >> ${man_file}
	done
}

# Check each of the images in the global variable arch_tags exist and
# Create the tag list from the arch_tags list.
function print_tags() {
	repo=$1
	img_list=""
	# Check if all the individual docker images exist for each expected arch
	for arch_tag in ${arch_tags}
	do
		trepo=${source_prefix}/${repo}
		check_image ${trepo}:${arch_tag}
		img_list="${img_list} ${trepo}:${arch_tag}"
	done
	print_manifest_cmd ${trepo} ${img_list}
}

# Build valid image tags using the tags.config file as the base
function build_tags() {
	vm=$1; shift
	ver=$1; shift;
	rel=$1; shift;
	os=$1; shift;
	build=$1; shift;
	rawtags=$*
	tmpfile=raw_arch_tags.$$.tmp

	# Get the list of supported arches for this vm / ver /os combo
	arches=$(parse_vm_entry ${vm} ${ver} ${os} "Architectures:")
	# Replace the proper version string in the tags
	rtags=$(echo ${rawtags} | sed "s/{{ JDK_${build}_VER }}/${rel}/gI; s/{{ OS }}/${os}/gI;");
	echo ${rtags} | sed "s/{{ *ARCH *}}/{{ARCH}}/" |
	# Separate the arch and the generic alias tags
	awk '{ a=0; n=0;
		for (i=1; i<=NF; i++) {
			if (match($i, "ARCH") > 0) {
				atags[a++]=sprintf(" %s", $i);
			} else {
				natags[n++]=sprintf(" %s", $i);
			}
		}
	} END {
		printf("arch_tags: "); for (key in atags) { printf"%s ", atags[key] }; printf"\n";
		printf("tag_aliases: "); for (key in natags) { printf"%s ", natags[key] }; printf"\n";
	}' > ${tmpfile}

	tag_aliases=$(cat ${tmpfile} | grep "^tag_aliases:" | sed "s/tag_aliases: //")
	raw_arch_tags=$(cat ${tmpfile} | grep "^arch_tags:" | sed "s/arch_tags: //")
	arch_tags=""
	# Iterate through the arch tags and expand to add the supported arches.
	for tag in ${raw_arch_tags}
	do
		for arch in ${arches}
		do
			atag=$(echo ${tag} | sed "s/{{ARCH}}/${arch}"/g)
			arch_tags="${arch_tags} ${atag}"
		done
	done
	rm -f ${tmpfile}
}

# Check if the manifest tool is installed
check_manifest_tool

if [ ! -z "$1" ]; then
	set_version $1
fi

# Set the OSes that will be built on based on the current arch
set_arch_os

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


# Populate the script to create the manifest list
echo "#!/bin/bash" > ${man_file}
echo  >> ${man_file}

# Go through each vm / os / build / type combination and build the manifest commands
# vm    = hotspot / openj9
# os    = alpine / ubuntu
# build = releases / nightly
# type  = full / slim
for vm in ${available_jvms}
do
	for os in ${oses}
	do
		builds=$(parse_vm_entry ${vm} ${version} ${os} "Build:")
		btypes=$(parse_vm_entry ${vm} ${version} ${os} "Type:")
		for build in ${builds}
		do
			shasums="${package}"_"${vm}"_"${version}"_"${build}"_sums
			jverinfo=${shasums}[version]
			eval jrel=\${$jverinfo}
			if [[ -z ${jrel} ]]; then
				continue;
			fi
			# Docker image tags cannot have "+" in them, replace it with "." instead.
			rel=$(echo ${jrel} | sed 's/+/./g')

			srepo=${source_repo}${version}
			if [ "${vm}" != "hotspot" ]; then
				srepo=${srepo}-${vm}
			fi
			for btype in ${btypes}
			do
				echo -n "INFO: Building tag list for [${vm}]-[${os}]-[${build}]-[${btype}]..."
				# Get the relevant tags for this vm / os / build / type combo from the tags.config file
				raw_tags=$(parse_tag_entry ${os} ${build} ${btype})
				build_tags ${vm} ${version} ${rel} ${os} ${build} ${raw_tags}
				echo "done"
				print_tags ${srepo}
			done
		done
	done
done

chmod +x ${man_file}
echo "INFO: Manifest commands in file: ${man_file}"
