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
set -eo pipefail

# Dockerfiles to be generated
version="9"
package="jdk"
osver="ubuntu alpine"

source ./common_functions.sh

if [ ! -z "$1" ]; then
	version=$1
	if [ ! -z "$(check_version $version)" ]; then
		echo "ERROR: Invalid Version"
		echo "Usage: $0 [${supported_versions}]"
		exit 1
	fi
fi

# source the hotspot and openj9 shasums scripts
supported_jvms=""
if [ -f hotspot_shasums_latest.sh ]; then
	source ./hotspot_shasums_latest.sh
	supported_jvms="hotspot"
fi
if [ -f openj9_shasums_latest.sh ]; then
	source ./openj9_shasums_latest.sh
	supported_jvms="${supported_jvms} openj9"
fi
if [ "${supported_jvms}" = "" ]; then
	echo "Run ./generate_latest_sums.sh to get the latest shasums first"
	exit 1
fi

# Generate the common license and copyright header
print_legal() {
	cat > $1 <<-EOI
	# ------------------------------------------------------------------------------
	#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
	#
	#                       PLEASE DO NOT EDIT IT DIRECTLY.
	# ------------------------------------------------------------------------------
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

	EOI
}

# Print the supported Ubuntu OS
print_ubuntu_os() {
	cat >> $1 <<-EOI
	FROM ubuntu:16.04

	EOI
}

# Print the supported Alpine OS
print_alpine_os() {
	cat >> $1 <<-EOI
	FROM alpine:3.6

	EOI
}

# Print the maintainer
print_maint() {
	cat >> $1 <<-EOI
	MAINTAINER Dinakar Guniguntala <dinakar.g@in.ibm.com> (@dinogun)
	EOI
}

# Select the ubuntu OS packages
print_ubuntu_pkg() {
	cat >> $1 <<'EOI'

RUN rm -rf /var/lib/apt/lists/* && apt-get clean && apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
EOI
}

# Select the alpine OS packages.
# Install GNU glibc as this OpenJDK build is compiled against glibc and not musl.
print_alpine_pkg() {
	cat >> $1 <<'EOI'

RUN apk --update add --no-cache ca-certificates curl openssl binutils xz \
    && GLIBC_VER="2.25-r0" \
    && ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" \
    && curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/${GLIBC_VER}.apk \
    && apk add --allow-untrusted /tmp/${GLIBC_VER}.apk \
    && curl -Ls https://www.archlinux.org/packages/core/x86_64/gcc-libs/download > /tmp/gcc-libs.tar.xz \
    && mkdir /tmp/gcc \
    && tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc \
    && mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib \
    && strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* \
    && apk del binutils \
    && rm -rf /tmp/${GLIBC_VER}.apk /tmp/gcc /tmp/gcc-libs.tar.xz /var/cache/apk/*
EOI
}

# Print the Java version that is being installed here
print_env() {
	srcpkg=$2
	shasums="${srcpkg}"_"${vm}"_"${ver}"_sums
	jverinfo=${shasums}[version]
	eval jver=\${$jverinfo}

	cat >> $1 <<-EOI

ENV JAVA_VERSION ${jver}

EOI
}

# OS independent portion (Works for both Alpine and Ubuntu)
print_java_install() {
	supported_arches=$(get_arches ${shasums})
	for sarch in ${supported_arches}
	do
		if [ "${sarch}" == "aarch64" ]; then
			cat >> $1 <<-EOI
       aarch64|arm64) \\
         ESUM='$(sarray=${shasums}[aarch64]; eval esum=\${$sarray}; echo ${esum})'; \\
         JAVA_URL="https://api.adoptopenjdk.net/${reldir}/releases/aarch64_linux/latest/binary"; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "ppc64le" ]; then
			cat >> $1 <<-EOI
       ppc64el|ppc64le) \\
         ESUM='$(sarray=${shasums}[ppc64le]; eval esum=\${$sarray}; echo ${esum})'; \\
         JAVA_URL="https://api.adoptopenjdk.net/${reldir}/releases/ppc64le_linux/latest/binary"; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "s390x" ]; then
			cat >> $1 <<-EOI
       s390x) \\
         ESUM='$(sarray=${shasums}[s390x]; eval esum=\${$sarray}; echo ${esum})'; \\
         JAVA_URL="https://api.adoptopenjdk.net/${reldir}/releases/s390x_linux/latest/binary"; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "x86_64" ]; then
			cat >> $1 <<-EOI
       amd64|x86_64) \\
         ESUM='$(sarray=${shasums}[x86_64]; eval esum=\${$sarray}; echo ${esum})'; \\
         JAVA_URL="https://api.adoptopenjdk.net/${reldir}/releases/x64_linux/latest/binary"; \\
         ;; \\
		EOI
		fi
	done
			cat >> $1 <<-EOI
       *) \\
         echo "Unsupported arch: \${ARCH}"; \\
         exit 1; \\
         ;; \\
    esac; \\
EOI
	cat >> $1 <<'EOI'
    curl -Lso /tmp/openjdk.tar.gz ${JAVA_URL}; \
    echo "${ESUM}  /tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz; \
    rm -f /tmp/openjdk.tar.gz;
EOI

}

# Print the main RUN command that installs Java on ubuntu.
print_ubuntu_java_install() {
	srcpkg=$2
	dstpkg=$3
	cat >> $1 <<-EOI
RUN set -eux; \\
    ARCH="\$(dpkg --print-architecture)"; \\
    case "\${ARCH}" in \\
EOI
	print_java_install ${file} ${srcpkg} ${dstpkg};
}

# Print the main RUN command that installs Java on alpine.
print_alpine_java_install() {
	srcpkg=$2
	dstpkg=$3
	cat >> $1 <<-EOI
RUN set -eux; \\
    ARCH="\$(apk --print-arch)"; \\
    case "\${ARCH}" in \\
EOI
	print_java_install ${file} ${srcpkg} ${dstpkg};
}

print_java_env() {
	JPATH="/opt/java/openjdk/${jver}/bin"
	TPATH="PATH=${JPATH}:\$PATH"

	cat >> $1 <<-EOI

ENV ${TPATH}
EOI
}

print_exclude_file() {
	srcpkg=$2
	dstpkg=$3
	if [ "${ver}" == "9" -a "${dstpkg}" == "sfj" ]; then
		cp sfj-exclude.txt `dirname ${file}`
		cat >> $1 <<-EOI
COPY sfj-exclude.txt /tmp

EOI
	fi
}

generate_java() {
	srcpkg=${pack};
	dstpkg=${pack};
	print_env ${file} ${srcpkg};
	print_exclude_file ${file} ${srcpkg} ${dstpkg};
	if [ "${os}" == "ubuntu" ]; then
		print_ubuntu_java_install ${file} ${srcpkg} ${dstpkg};
	elif [ "${os}" == "alpine" ]; then
		print_alpine_java_install ${file} ${srcpkg} ${dstpkg};
	fi
	print_java_env ${file} ${srcpkg};
}

generate_ubuntu() {
	file=$1
	mkdir -p `dirname ${file}` 2>/dev/null
	echo -n "Writing ${file} ... "
	print_legal ${file};
	print_ubuntu_os ${file};
	print_maint ${file};
	print_ubuntu_pkg ${file};
	generate_java ${file};
	echo "done"
}

generate_alpine() {
	file=$1
	mkdir -p `dirname ${file}` 2>/dev/null
	echo -n "Writing ${file} ... "
	print_legal ${file};
	print_alpine_os ${file};
	print_maint ${file};
	print_alpine_pkg ${file};
	generate_java ${file};
	echo "done"
}

# Iterate through all the Java versions for each of the supported packages,
# architectures and supported Operating Systems.
for ver in ${version}
do
	for pack in ${package}
	do
		for os in ${osver}
		do
			for vm in ${supported_jvms}
			do
				file=${ver}/${pack}/${os}/Dockerfile.${vm}
				if [ "$vm" == "hotspot" ]; then
					reldir="openjdk${version}";
				elif [ "$vm" == "openj9" ]; then
					reldir="openjdk${version}-openj9";
				fi
				# Ubuntu is supported for everything
				if [ "${os}" == "ubuntu" ]; then
					generate_ubuntu ${file}
				elif [ "${os}" == "alpine" ]; then
					generate_alpine ${file}
				fi
			done
		done
	done
done
