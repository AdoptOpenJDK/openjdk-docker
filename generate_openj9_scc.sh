#!/bin/sh
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

unset OPENJ9_JAVA_OPTIONS

# Default size for SCC
SCC_SIZE="50m"

# Runs for generating SCC
SCC_GEN_RUNS_COUNT=3

# Intitialise default / allowed sample app status
RUN_TOMCAT=true

# sha512 checksums
TOMCAT_CHECKSUM="0db27185d9fc3174f2c670f814df3dda8a008b89d1a38a5d96cbbe119767ebfb1cf0bce956b27954aee9be19c4a7b91f2579d967932207976322033a86075f98"

# App download locations
DOWNLOAD_PATH_TOMCAT=/tmp/tomcat

# App installation locations
INSTALL_PATH_TOMCAT=/opt/tomcat-home

# URL's for the artifacts
TOMCAT_DWNLD_URL="https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.35/bin/apache-tomcat-9.0.35.tar.gz"

# Check and download tomcat
check_to_download_tomcat() {
    if [ "${RUN_TOMCAT}" = true ]; then
        # Creating a temporary directory for tomcat download
        mkdir -p "${DOWNLOAD_PATH_TOMCAT}" "${INSTALL_PATH_TOMCAT}"

        # Downloading tomcat
        if curl --fail -o "${DOWNLOAD_PATH_TOMCAT}"/tomcat.tar.gz "${TOMCAT_DWNLD_URL}"; then
            # Verifying checksum
            if ! echo "${TOMCAT_CHECKSUM} *${DOWNLOAD_PATH_TOMCAT}/tomcat.tar.gz" | sha512sum -c -; then
                echo "WARNING: Checksum Mismatch. SCC not generated"
                # Remove the tar file and installation folder
                rm -rf "${DOWNLOAD_PATH_TOMCAT}" "${INSTALL_PATH_TOMCAT}"
                # Not exiting as we don't stop build due to SCC failures
                # Setting RUN_TOMCAT to `false` to avoid futher process of generating SCC
                RUN_TOMCAT=false
            else
                # Extracting tomcat
                tar -xvzf "${DOWNLOAD_PATH_TOMCAT}"/tomcat.tar.gz -C "${INSTALL_PATH_TOMCAT}" --strip-components=1
            fi
        else
            echo "WARNING: Tomcat download failed. SCC not generated"
            # Not exiting here as we may add other applications in future and
            # we don't stop build due to SCC failures
            # Setting RUN_TOMCAT to `false` to avoid futher process of generating SCC
            RUN_TOMCAT=false
        fi

        # Removing the tar file
        rm -rf "${DOWNLOAD_PATH_TOMCAT}"
    fi
}

# Run the applications for specified iterations
run_apps() {
    if [ $SCC_GEN_RUNS_COUNT -gt 0 ]; then
        for i in $(seq 1 $SCC_GEN_RUNS_COUNT)
        do
            # Check for app availability and run them to generate SCC
            if [ "${RUN_TOMCAT}" = true ]; then
                run_tomcat_and_stop
            fi
        done
    fi
}


# function to download the applications
download_and_install_artifacts() {
    # check for tomcat
    check_to_download_tomcat
}

# dry run to right size the cache
dry_run() {
    # Creating base layer first instead of running sample programs to generate SCC directly
    java -Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal,createLayer -Xscmx$SCC_SIZE -version

    # Pointing cache for sample program runs
    export OPENJ9_JAVA_OPTIONS="-Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal"

    # Run the applications to generate SCC
    run_apps

    FULL=$( (java -Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,printallStats || true) 2>&1 | awk '/^Cache is [0-9.]*% .*full/ {print substr($3, 1, length($3)-1)}')

    java -Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,destroy || true

    SCC_SIZE="$(printf '%s' "SCC_SIZE" | cut -c 1-$((${#SCC_SIZE}-1)))"

    SCC_SIZE=$(awk "BEGIN {print int($SCC_SIZE * $FULL / 100.0)}")

    [ "${SCC_SIZE}" -eq 0 ] && SCC_SIZE=1

    SCC_SIZE="${SCC_SIZE}m"

    # Re-generating cache with new size
    java -Xshareclasses:name=openj9_system_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal,createLayer -Xscmx$SCC_SIZE -version

    unset OPENJ9_JAVA_OPTIONS
}

# Generate SCC by running apps
generate_scc() {
    # Pointing cache for sample app runs
    export OPENJ9_JAVA_OPTIONS="-Xshareclasses:name=openj9_system_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal"
    
    # Run the applications to generate SCC
    run_apps

    # Checking the cache level
    FULL=$( (java -Xshareclasses:name=openj9_system_scc,cacheDir=/opt/java/.scc,printallStats || true) 2>&1 | awk '/^Cache is [0-9.]*% .*full/ {print substr($3, 1, length($3)-1)}')

    echo "SCC layer is $FULL% full."
}

# Remove the downloaded sample apps
remove_artifacts() {
    # Command to remove apps
    REMOVE_APPS="rm -rf"

    # check for tomcat
    if [ "${RUN_TOMCAT}" = true ]; then
        REMOVE_APPS="${REMOVE_APPS} ${INSTALL_PATH_TOMCAT}"
    fi

    eval "$REMOVE_APPS"
}

# Run tomcat and stop it after the startup
run_tomcat_and_stop() {
    # Start tomcat wait till it comes up shut it down
    "${INSTALL_PATH_TOMCAT}"/bin/startup.sh
    # wait till tomcat starts -  wait for 5 seconds
    sleep 5
    # Stop tomcat
    "${INSTALL_PATH_TOMCAT}"/bin/shutdown.sh
    # wait till tomcat stops -  wait for 5 seconds
    sleep 5
}

# Changing scc directory permission to 0777
change_permissions() {
    if [ -d "/opt/java/.scc" ]; then
        chmod -R 0777 /opt/java/.scc
    fi
}

# Download the sample apps and install
download_and_install_artifacts

# Dry run for SCC generation (To get exact size)
dry_run

# Generate SCC
generate_scc

# Remove installed artifacts
remove_artifacts

# Change permission of `/opt/java/.scc` to be accessible for all users of the image
change_permissions
