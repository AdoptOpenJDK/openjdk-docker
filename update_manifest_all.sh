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

source ./common_functions.sh

for ver in ${supported_versions}
do
	# Cleanup any old containers, images and manifest entries.
	cleanup_images
	cleanup_manifest

	# Remove any temporary files
	rm -f hotspot_shasums_latest.sh openj9_shasums_latest.sh manifest_commands.sh

	echo "==============================================================================="
	echo "                                                                               "
	echo "                 Generating Manifest Entries for Version ${ver}                "
	echo "                                                                               "
	echo "==============================================================================="
	./generate_manifest_script.sh ${ver}

	err=$?
	if [ ${err} != 0 -o ! -f ./manifest_commands.sh ]; then
		echo
		echo "ERROR: Docker Build for version ${ver} failed."
		echo
		exit 1;
	fi
	echo
	echo "WARNING: Pushing to AdoptOpenJDK repo on hub.docker.com"
	echo "WARNING: If you did not intend this, quit now. (Sleep 5)"
	echo
	sleep 5

	# Now push the manifest entries to hub.docker.com
	echo "==============================================================================="
	echo "                                                                               "
	echo "                 Pushing Manifest Entries for Version ${ver}                   "
	echo "                                                                               "
	echo "==============================================================================="
	cat manifest_commands.sh
	./manifest_commands.sh

	# Remove any temporary files
	rm -f hotspot_shasums_latest.sh openj9_shasums_latest.sh manifest_commands.sh

	# Now test the images from hub.docker.com
	echo "==============================================================================="
	echo "                                                                               "
	echo "                    Testing Docker Images for Version ${ver}                   "
	echo "                                                                               "
	echo "==============================================================================="
	# We will test all image types
	cp ${test_image_types_all_file} ${test_image_types_file}
	./test_multiarch.sh ${ver}
done

# Cleanup any old containers, images and manifest entries.
cleanup_images
cleanup_manifest
