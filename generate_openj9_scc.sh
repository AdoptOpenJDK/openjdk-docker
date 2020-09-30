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

# is running on ubuntu or debian - package manager apt
IS_APT_ENV=false
# Intitialise default / allowed sample app status
RUN_ECLIPSE=false
RUN_TOMCAT=true

# Intitialise default / required packages status
INSTALL_GTK=false
INSTALL_XVFB=false

# App download locations
DOWNLOAD_PATH_ECLIPSE=/tmp/eclipse
DOWNLOAD_PATH_TOMCAT=/tmp/tomcat

# App installation locations
INSTALL_PATH_ECLIPSE="${HOME}"/eclipse-home
INSTALL_PATH_TOMCAT="${HOME}"/tomcat-home

# URL's for the artifacts
ECLIPSE_DWNLD_URL="http://www.mirrorservice.org/sites/download.eclipse.org/eclipseMirror/technology/epp/downloads/release/2020-06/M3/eclipse-java-2020-06-M3-linux-gtk-x86_64.tar.gz"
TOMCAT_DWNLD_URL="https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.35/bin/apache-tomcat-9.0.35.tar.gz"

# Check and downlaod eclipse
check_to_download_eclipse() {
    if [ "${RUN_ECLIPSE}" = true ]; then
        # Creating a temporary directory for eclipse download
        mkdir -p "${DOWNLOAD_PATH_ECLIPSE}" "${INSTALL_PATH_ECLIPSE}"

        # Downloading eclipse
        if curl --fail -o "${DOWNLOAD_PATH_ECLIPSE}"/eclipse.tar.gz  "${ECLIPSE_DWNLD_URL}"; then
            # Extracting eclipse
            tar -xvzf "${DOWNLOAD_PATH_ECLIPSE}"/eclipse.tar.gz -C "$INSTALL_PATH_ECLIPSE" --strip-components=1
        else
            RUN_ECLIPSE=false
        fi

        # Removing the tar file
        rm -rf "${DOWNLOAD_PATH_ECLIPSE}"
    fi
}

# Check and download tomcat
check_to_download_tomcat() {
    if [ "${RUN_TOMCAT}" = true ]; then
        # Creating a temporary directory for tomcat download
        mkdir -p "${DOWNLOAD_PATH_TOMCAT}" "${INSTALL_PATH_TOMCAT}"

        # Downloading tomcat
        if curl --fail -o "${DOWNLOAD_PATH_TOMCAT}"/tomcat.tar.gz "${TOMCAT_DWNLD_URL}"; then
            # Extracting tomcat
            tar -xvzf "${DOWNLOAD_PATH_TOMCAT}"/tomcat.tar.gz -C "${INSTALL_PATH_TOMCAT}" --strip-components=1
        else
            RUN_TOMCAT=false
        fi

        # Removing the tar file
        rm -rf "${DOWNLOAD_PATH_TOMCAT}"
    fi
}

# ubuntu/debian install packages required for eclipse
apt_install_packages() {
    # update the repositories
    apt update

    # Set non-interactive frontend (to avoid `tzdata` config options selection)
    APT_INSTALL_CMD="DEBIAN_FRONTEND=noninteractive"
    APT_INSTALL_CMD="${APT_INSTALL_CMD} apt install -y"

    if [ "${INSTALL_GTK}" = true ]; then
        # install gtk+3.0
        APT_INSTALL_CMD="${APT_INSTALL_CMD} gtk+3.0"
    fi

    if [ "${INSTALL_XVFB}" = true ]; then
        # install xvfb
        APT_INSTALL_CMD="${APT_INSTALL_CMD} xvfb"
    fi

    eval "${APT_INSTALL_CMD}"
}

# Check if any application needs virtual screen and launch it
check_and_start_xvfb() {
    # check if `xvfb` installed
    if [ "${INSTALL_XVFB}" = true ]; then
        # Spawning a virtual screen for GUI apps
        Xvfb :1 -ac -screen 0 1024x768x8 &
        # Saving the PID
        XVFB_PID=$!
        # Saving older display value
        OLD_DISPLAY=$DISPLAY
        # Setting DISPLAY to created screen
        export DISPLAY=:1
    fi
}

# Kill the created virtual screen
check_and_stop_xvfb() {
    # check if `xvfb` installed
    if [ "${INSTALL_XVFB}" = true ]; then
        # Killing `xvfb` process to remove screen
        kill -9 $XVFB_PID
        # Setting back the DISPLAY to older value
        export DISPLAY=$OLD_DISPLAY
    fi
}

# Run the applications for specified iterations
run_apps() {
    if [ $SCC_GEN_RUNS_COUNT -gt 0 ]; then
        for i in $(seq 1 $SCC_GEN_RUNS_COUNT)
        do
            if [ "${RUN_ECLIPSE}" = true ]; then
                run_eclipse_and_stop
            fi
            if [ "${RUN_TOMCAT}" = true ]; then
                run_tomcat_and_stop
            fi
        done
    fi
}

# function to install packages
install_packages() {
    if [ "${IS_APT_ENV}" = true ]; then
        apt_install_packages
    fi
}

# function to download the applications
download_and_install_artifacts() {

    # check for eclipse
    check_to_download_eclipse

    # check for tomcat
    check_to_download_tomcat

}

# dry run to right size the cache
dry_run() {
    # Creating base layer first instead of running sample programs to generate SCC directly
    java -Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal,createLayer -Xscmx$SCC_SIZE -version

    # Pointing cache for sample program runs
    export OPENJ9_JAVA_OPTIONS="-Xshareclasses:name=dry_run_scc,cacheDir=/opt/java/.scc,bootClassesOnly,nonFatal"

    # check if we need xvfb for running application and start a virtual screen if required
    check_and_start_xvfb

    # Run the applications to generate SCC
    run_apps

    # check if started a virtual screen and kill the process
    check_and_stop_xvfb

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

    # check if we need xvfb for running application and start a virtual screen if required
    check_and_start_xvfb

    # Run the applications to generate SCC
    run_apps

    # check if started a virtual screen and kill the process
    check_and_stop_xvfb

    # Checking the cache level
    FULL=$( (java -Xshareclasses:name=openj9_system_scc,cacheDir=/opt/java/.scc,printallStats || true) 2>&1 | awk '/^Cache is [0-9.]*% .*full/ {print substr($3, 1, length($3)-1)}')

    echo "SCC layer is $FULL% full."
}

# Remove the downloaded sample apps
remove_artifacts() {
    # Command to remove apps
    REMOVE_APPS="rm -rf"

    # check for eclipse
    if [ "${RUN_ECLIPSE}" = true ]; then
        REMOVE_APPS="${REMOVE_APPS} ${INSTALL_PATH_ECLIPSE}"
    fi

    # check for tomcat
    if [ "${RUN_TOMCAT}" = true ]; then
        REMOVE_APPS="${REMOVE_APPS} ${INSTALL_PATH_TOMCAT}"
    fi

    eval "$REMOVE_APPS"
}

# Run eclipse and stop it after the startup
run_eclipse_and_stop() {
    # Starting eclipse in background
    "${INSTALL_PATH_ECLIPSE}"/eclipse/eclipse &
    # Saving eclipse PID
    ECLIPSE_PID=$!
    # Waiting for eclipse to start - Sleeping for 1 minute
    sleep 1m
    # Killing eclipse process
    kill -9 $ECLIPSE_PID
    # Waiting for process to be killed - Sleeping for 10 seconds
    sleep 10s
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

# Remove the installed packages
remove_packages() {
    if [ "${IS_APT_ENV}" = true ]; then
        APT_REMOVE_CMD="apt --purge -y autoremove"

        if [ "${INSTALL_GTK}" = true ]; then
            # remove gtk+3.0
            APT_REMOVE_CMD="${APT_REMOVE_CMD} gtk+3.0"
        fi

        if [ "${INSTALL_XVFB}" = true ]; then
            # remove xvfb
            APT_REMOVE_CMD="${APT_REMOVE_CMD} xvfb"
        fi

        eval "${APT_REMOVE_CMD}"
    fi
}

# Changing scc directory permission to 0755
change_permissions() {
    if [ -d "/opt/java/.scc" ]; then
        chmod -R 0775 /opt/java/.scc
    fi
}

# check for OS release file
if [ -f /etc/os-release ]; then
    # load file to get the ID (OS name)
    # shellcheck disable=SC1091
    . /etc/os-release
    OS=$ID
fi

# Check if OS is ubuntu/debian (we can run eclipse as packages required for it are available)
if [ "${OS}" = "ubuntu" ]  || [ "${OS}" = "debian" ]; then
    # set IS_APT_ENV true
    IS_APT_ENV=true

    # Set eclipse run to `true`
    RUN_ECLIPSE=true

    # Set the required packages for eclipse to `true`
    INSTALL_GTK=true
    INSTALL_XVFB=true

    # Call function `install_pkgs_via_apt` to install packages
    install_packages
fi

# Download the sample apps and install
download_and_install_artifacts

# Dry run for SCC generation (To get exact size)
dry_run

# Generate SCC
generate_scc

# Remove installed artifacts
remove_artifacts

# Remove packages
remove_packages

# Change permission of `/opt/java/.scc` to be accessible for all users of the image
change_permissions
