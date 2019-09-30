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
set -o pipefail

source ./common_functions.sh

for ver in ${supported_versions}
do
	# Cleanup any old containers and images
	cleanup_images
	cleanup_manifest

	# Remove any temporary files
	rm -f hotspot_shasums_latest.sh openj9_shasums_latest.sh push_commands.sh

	echo "==============================================================================="
	echo "                                                                               "
	echo "                      Writing Dockerfiles for Version ${ver}                   "
	echo "                                                                               "
	echo "==============================================================================="
	# Generate the Dockerfiles for the unofficial images.
	./update_multiarch.sh ${ver}

	# hotspot.config and openj9.config now only contain the unofficial image list.
	# hotspot-official.config and openj9-official.config contain the officially supported list.
	# We need to generate the Dockerfiles for both to update the complete set.
	cp config/hotspot-official.config config/hotspot.config
	cp config/openj9-official.config config/openj9.config

	# Now generate the Dockerfiles for the official images.
	./update_multiarch.sh ${ver}

	# Restore the original files.
	git checkout config/hotspot.config config/openj9.config
done
