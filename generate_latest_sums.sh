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

version="9"
root_dir="$PWD"

source ./common_functions.sh

if [ ! -z "$1" ]; then
	set_version $1
fi

echo "Getting latest shasum info for major version: ${version}"
for vm in ${all_jvms}
do
	get_shasums ${version} ${vm}
done
