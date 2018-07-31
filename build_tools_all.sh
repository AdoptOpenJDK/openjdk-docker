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

source ./common_functions.sh

# Cleanup any old containers and images
cleanup_images

for ver in ${supported_versions}
do
	# Remove any temporary files
	rm -f hotspot_shasums_latest.sh openj9_shasums_latest.sh push_commands.sh

	echo "==============================================================================="
	echo "                                                                               "
	echo "                Building Tools Docker Images for Version ${ver}                "
	echo "                                                                               "
	echo "==============================================================================="
	./build_tools_latest.sh ${ver}

	err=$?
	if [ ${err} != 0 -o ! -f ./push_commands.sh ]; then
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
	# Now push the images to hub.docker.com
	echo "==============================================================================="
	echo "                                                                               "
	echo "                Pushing Tools Docker Images for Version ${ver}                 "
	echo "                                                                               "
	echo "==============================================================================="
	cat push_commands.sh
	./push_commands.sh

	# Remove any temporary files
	rm -f hotspot_shasums_latest.sh openj9_shasums_latest.sh push_commands.sh

	# Now test the images from hub.docker.com
	echo "==============================================================================="
	echo "                                                                               "
	echo "                Testing Tools Docker Images for Version ${ver}                 "
	echo "                                                                               "
	echo "==============================================================================="
	# Only test the just created tools docker image tags
	echo "test_tools" > ${test_image_types_file}
	./test_tools.sh ${ver}
done
