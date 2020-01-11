#!/usr/bin/env bash

################################################################################
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
################################################################################

################################################################################
#
# This script downloads and executes hadolint. It will be run automatically
# by Travis on every push. You can run it manually to validate your changes.
#
################################################################################

set -eu

hadolintDir="hadolint"
shellcheckDir="shellcheck"
hadolintVersion="1.17.4"
hadolintCmd="${hadolintDir}/hadolint"
shellcheckCmd="${shellcheckDir}/shellcheck"

install_hadolint()
{
  echo "Installing hadolint"
  mkdir -p "${hadolintDir}"

  wget -O ${hadolintDir}/hadolint "https://github.com/hadolint/hadolint/releases/download/v${hadolintVersion}/hadolint-Linux-x86_64"
  chmod +x "${hadolintCmd}"
  "${hadolintCmd}" --version
}

install_shellcheck()
{
  echo "Installing shellcheck"
  mkdir -p "${shellcheckDir}"

  wget -O- "https://storage.googleapis.com/shellcheck/shellcheck-stable.linux.x86_64.tar.xz" | tar xvfJ - -C ${shellcheckDir} --strip-components=1
  chmod +x "${shellcheckCmd}"
  "${shellcheckCmd}" --version
}

check_dockerfiles()
{
  find . -name "Dockerfile*" -exec sh -c "./${hadolintCmd}  {};echo " \;
}

check_sh_scripts()
{
  shopt -s globstar
  "./${shellcheckCmd}" ./**/*.sh
}

if [[ ! -d "${hadolintDir}" ]] ; then
  install_hadolint
fi
if [[ ! -d "${shellcheckDir}" ]] ; then
  install_shellcheck
fi
check_dockerfiles
check_sh_scripts
