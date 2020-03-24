#!/usr/bin/env bash
if [ -z "${SNYK_AUTH_TOKEN}" ];then
  printf "Snyk authentication token not set, skipping snyk analysis\n"
  return
fi
set -o pipefail
export SNYK_ENABLED=0
if test -f "$HOME/.nvm/nvm.sh"; then
  echo "nvm found"
else
  echo "No nvm on machine, snyk check will be skipped"
  exit 0
fi

# shellcheck disable=SC1090
source "$HOME/.nvm/nvm.sh"

echo "Installing node..."
nvm install node

echo "Installing snyk.."
npm install -g snyk

echo "Snyk version: $(snyk -v)"

printf "Snyk installed succesfully\n"
printf "Authenticating snyk\n"

if ! snyk auth "${SNYK_AUTH_TOKEN}"; then
  echo "snyk auth failed, snyk disabled"
else
  echo "snyk auth succeed, enabling snyk"
  export SNYK_ENABLED=1
fi


