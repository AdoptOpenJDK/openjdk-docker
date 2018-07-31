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
version="9"

source ./common_functions.sh
source ./dockerfile_functions.sh

if [ ! -z "$1" ]; then
	set_version $1
fi

# Set the OSes that will be built on based on the current arch
set_arch_os

# Create the build tools dockerfiles
function build_tool_images() {
	vm=$1;
	os=$2;
	build=$3;
	btype=$4;

	# Get the tag alias to generate the build tools Dockerfiles
	build_tags ${vm} ${os} ${build} ${btype}
	# build_tags populates the array tag_aliases, but we just need the first element
	# The first element corresponds to the tag alias			
	tags_arr=(${tag_aliases});
	tag_alias=${tags_arr[0]};

	for tool in ${all_tools}
	do
		tool_dir=$(parse_config_file ${tool} ${version} ${os} "Directory:")
		file=Dockerfile.${vm}.${build}.${btype}
		if [ ! -f ${tool_dir}/${file} ]; then
			continue;
		fi
		tag=${tool}-${tag_alias}
		# The target repo is different for different VMs
		if [ "${vm}" == "hotspot" ]; then
			trepo=${target_repo}${version}
		else
			trepo=${target_repo}${version}-${vm}
		fi
		echo "INFO: Building ${trepo} ${tag} from ${file}..."
		pushd ${tool_dir} >/dev/null
		build_image ${file} ${trepo}:${tag}
		popd >/dev/null

		# Docker image has been built successfully.
		# Add the command to push this image to docker hub.
		echo "docker push ${trepo}:${tag}" >> ${push_cmdfile}
	done
}

# Script that has the push commands for the images that we are building.
echo "#!/bin/bash" > ${push_cmdfile}
echo >> ${push_cmdfile}

# Loop through all the valid vm / os / build / build type combinations
# for each of the build tools.
for vm in ${all_jvms}
do
	for os in ${oses}
	do
		# Build = Release or Nightly
		builds=$(parse_config_file ${vm} ${version} ${os} "Build:")
		# Type = Full or Slim
		btypes=$(parse_config_file ${vm} ${version} ${os} "Type:")
		dir=$(parse_config_file ${vm} ${version} ${os} "Directory:")

		for build in ${builds}
		do
			echo "Getting latest shasum info for [ ${version} ${vm} ${build} ]"
			get_shasums ${version} ${vm} ${build}
			# Source the generated shasums file to access the array
			if [ -f ${vm}_shasums_latest.sh ]; then
				source ./${vm}_shasums_latest.sh
			else
				continue;
			fi
			# Check if the VM is supported for the current arch
			shasums="${package}"_"${vm}"_"${version}"_"${build}"_sums
			sup=$(vm_supported_onarch ${vm} ${shasums})
			if [ -z "${sup}" ]; then
				continue;
			fi
			# Generate all the Dockerfiles for each of the builds and build types
			for btype in ${btypes}
			do
				# Generate any build tools dockerfiles that uses
				# the above docker image as the base image.
				create_build_tool_dockerfiles ${vm} ${os} ${build} ${btype}

				# Now build the corresponding docker images.
				build_tool_images ${vm} ${os} ${build} ${btype}
			done
		done
	done
done
chmod +x ${push_cmdfile}

echo
echo "INFO: The push commands are available in file ${push_cmdfile}"
