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
	if [ ! -z "$(check_version ${version})" ]; then
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
if [ "${supported_jvms}" == "" ]; then
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
	FROM alpine:3.7

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
    && curl -Ls https://www.archlinux.org/packages/core/x86_64/zlib/download > /tmp/libz.tar.xz \
    && mkdir /tmp/libz \
    && tar -xf /tmp/libz.tar.xz -C /tmp/libz \
    && mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib \
    && apk del binutils \
    && rm -rf /tmp/${GLIBC_VER}.apk /tmp/gcc /tmp/gcc-libs.tar.xz /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*
EOI
}

# Print the Java version that is being installed here
print_env() {
	shasums="${package}"_"${vm}"_"${version}"_"${build}"_sums
	jverinfo=${shasums}[version]
	eval jver=\${$jverinfo}

	cat >> $1 <<-EOI

ENV JAVA_VERSION ${jver}

EOI
}

# OS independent portion (Works for both Alpine and Ubuntu)
print_java_install_pre() {
	bld=$2
	typ=$3
	supported_arches=$(get_arches ${shasums})
	for sarch in ${supported_arches}
	do
		if [ "${sarch}" == "aarch64" ]; then
			cat >> $1 <<-EOI
       aarch64|arm64) \\
         ESUM='$(sarray=${shasums}[aarch64]; eval esum=\${$sarray}; echo ${esum})'; \\
         JAVA_URL="https://api.adoptopenjdk.net/${reldir}/${bld}/aarch64_linux/latest/binary"; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "ppc64le" ]; then
			cat >> $1 <<-EOI
       ppc64el|ppc64le) \\
         ESUM='$(sarray=${shasums}[ppc64le]; eval esum=\${$sarray}; echo ${esum})'; \\
         JAVA_URL="https://api.adoptopenjdk.net/${reldir}/${bld}/ppc64le_linux/latest/binary"; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "s390x" ]; then
			cat >> $1 <<-EOI
       s390x) \\
         ESUM='$(sarray=${shasums}[s390x]; eval esum=\${$sarray}; echo ${esum})'; \\
         JAVA_URL="https://api.adoptopenjdk.net/${reldir}/${bld}/s390x_linux/latest/binary"; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "x86_64" ]; then
			cat >> $1 <<-EOI
       amd64|x86_64) \\
         ESUM='$(sarray=${shasums}[x86_64]; eval esum=\${$sarray}; echo ${esum})'; \\
         JAVA_URL="https://api.adoptopenjdk.net/${reldir}/${bld}/x64_linux/latest/binary"; \\
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
    jdir=$(dirname $(dirname $(find /opt/java/openjdk -name javac))); \
    mv ${jdir}/* /opt/java/openjdk; \
EOI
}

print_java_install_post() {
	cat >> $1 <<-EOI
    rm -rf \${jdir} /tmp/openjdk.tar.gz;
EOI
}

# Call the script to create the slim package
print_ubuntu_slim_package() {
	cat >> $1 <<-EOI
    export PATH="${jhome}/bin:\$PATH"; \\
    apt-get update; apt-get install -y --no-install-recommends binutils; \\
    /usr/local/bin/slim-java.sh ${jhome}; \\
    apt-get remove -y binutils; \\
    rm -rf /var/lib/apt/lists/*; \\
EOI
}

print_alpine_slim_package() {
	cat >> $1 <<-EOI
    export PATH="${jhome}/bin:\$PATH"; \\
    apk --update add --no-cache bash binutils; \\
    /usr/local/bin/slim-java.sh ${jhome}; \\
    apk del bash binutils; \\
    rm -rf /var/cache/apk/*; \\
EOI
}

# Print the main RUN command that installs Java on ubuntu.
print_ubuntu_java_install() {
	bld=$2
	typ=$3
	cat >> $1 <<-EOI
RUN set -eux; \\
    ARCH="\$(dpkg --print-architecture)"; \\
    case "\${ARCH}" in \\
EOI
	print_java_install_pre ${file} ${bld} ${typ}
	if [ "${typ}" == "slim" ]; then
		print_ubuntu_slim_package $1
	fi
	print_java_install_post $1
}

# Print the main RUN command that installs Java on alpine.
print_alpine_java_install() {
	bld=$2
	typ=$3
	cat >> $1 <<-EOI
RUN set -eux; \\
    ARCH="\$(apk --print-arch)"; \\
    case "\${ARCH}" in \\
EOI
	print_java_install_pre ${file} ${bld} ${typ}
	if [ "${typ}" == "slim" ]; then
		print_alpine_slim_package $1
	fi
	print_java_install_post $1
}

print_java_env() {
	jhome="/opt/java/openjdk"

	cat >> $1 <<-EOI

ENV JAVA_HOME=${jhome} \\
    PATH="${jhome}/bin:\$PATH"
EOI
}

copy_slim_script() {
	if [ "${typ}" == "slim" ]; then
		cat >> $1 <<-EOI
COPY slim-java.sh /usr/local/bin

EOI
	fi
}

generate_ubuntu() {
	file=$1
	bld=$2
	typ=$3
	mkdir -p `dirname ${file}` 2>/dev/null
	echo -n "Writing ${file} ... "
	print_legal ${file};
	print_ubuntu_os ${file};
	print_maint ${file};
	print_ubuntu_pkg ${file};
	print_env ${file} ${bld} ${typ};
	copy_slim_script ${file};
	print_ubuntu_java_install ${file} ${bld} ${typ};
	print_java_env ${file} ${bld} ${typ};
	echo "done"
}

generate_alpine() {
	file=$1
	bld=$2
	typ=$3
	mkdir -p `dirname ${file}` 2>/dev/null
	echo -n "Writing ${file} ... "
	print_legal ${file};
	print_alpine_os ${file};
	print_maint ${file};
	print_alpine_pkg ${file};
	print_env ${file} ${bld} ${typ};
	copy_slim_script ${file};
	print_alpine_java_install ${file} ${bld} ${typ};
	print_java_env ${file} ${bld} ${typ};
	echo "done"
}

# Iterate through all the Java versions for each of the supported packages,
# architectures and supported Operating Systems.
for vm in ${supported_jvms}
do
	oses=$(cat ${vm}.config | grep "OS:" | sed "s/OS: //")
	for os in ${oses}
	do
		# Build = Release or Nightly
		builds=$(parse_vm_entry ${vm} ${version} ${os} "Build:")
		# Type = Full or Slim
		types=$(parse_vm_entry ${vm} ${version} ${os} "Type:")
		dir=$(parse_vm_entry ${vm} ${version} ${os} "Directory:")

		for build in ${builds}
		do
			shasums="${package}"_"${vm}"_"${version}"_"${build}"_sums
			jverinfo=${shasums}[version]
			eval jver=\${$jverinfo}
			if [[ -z ${jver} ]]; then
				continue;
			fi
			for typ in ${types}
			do
				file=${dir}/Dockerfile.${vm}.${build}.${typ}
				# Copy the script to generate slim builds.
				if [ "${typ}" = "slim" ]; then
					cp slim-java.sh ${dir}
				fi
				reldir="openjdk${version}";
				if [ "${vm}" != "hotspot" ]; then
					reldir="${reldir}-${vm}";
				fi
				generate_${os} ${file} ${build} ${typ}
			done
		done
	done
done
