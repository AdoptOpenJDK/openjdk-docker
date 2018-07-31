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
print_ubuntu_ver() {
	local_build=$2
	local_build_type=$3

# Use ubuntu:18.04 for the slim and nightly builds.
if [ "${local_build}" == "nightly" -o "${local_build_type}" == "slim" ]; then
	os_version="18.04"
else
	os_version="16.04"
fi

	cat >> $1 <<-EOI
	FROM ubuntu:${os_version}

	EOI
}

# Print the supported Alpine OS
print_alpine_ver() {
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

RUN rm -rf /var/lib/apt/lists/* && apt-get clean && apt-get update && apt-get upgrade -y \
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
	btype=$3

	supported_arches=$(get_arches ${shasums})
	for sarch in ${supported_arches}
	do
		if [ "${sarch}" == "aarch64" ]; then
			cat >> $1 <<-EOI
       aarch64|arm64) \\
         ESUM='$(sarray=${shasums}[aarch64]; eval esum=\${$sarray}; echo ${esum})'; \\
         JAVA_URL='$(get_v2_url binary ${bld} ${vm} jdk latest aarch64)'; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "ppc64le" ]; then
			cat >> $1 <<-EOI
       ppc64el|ppc64le) \\
         ESUM='$(sarray=${shasums}[ppc64le]; eval esum=\${$sarray}; echo ${esum})'; \\
         JAVA_URL='$(get_v2_url binary ${bld} ${vm} jdk latest ppc64le)'; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "s390x" ]; then
			cat >> $1 <<-EOI
       s390x) \\
         ESUM='$(sarray=${shasums}[s390x]; eval esum=\${$sarray}; echo ${esum})'; \\
         JAVA_URL='$(get_v2_url binary ${bld} ${vm} jdk latest s390x)'; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "x86_64" ]; then
			cat >> $1 <<-EOI
       amd64|x86_64) \\
         ESUM='$(sarray=${shasums}[x86_64]; eval esum=\${$sarray}; echo ${esum})'; \\
         JAVA_URL='$(get_v2_url binary ${bld} ${vm} jdk latest x64)'; \\
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
    sha256sum /tmp/openjdk.tar.gz; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    echo "${ESUM}  /tmp/openjdk.tar.gz" | sha256sum -c -; \
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

# Call the script to create the slim package for Ubuntu
# Install binutils for this phase as we need the "strip" command
# Uninstall once done
print_ubuntu_slim_package() {
	cat >> $1 <<-EOI
    export PATH="${jhome}/bin:\$PATH"; \\
    apt-get update; apt-get install -y --no-install-recommends binutils; \\
    /usr/local/bin/slim-java.sh ${jhome}; \\
    apt-get remove -y binutils; \\
    rm -rf /var/lib/apt/lists/*; \\
EOI
}

# Call the script to create the slim package for Alpine
# Install binutils for this phase as we need the "strip" command
# Uninstall once done
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
	btype=$3
	cat >> $1 <<-EOI
RUN set -eux; \\
    ARCH="\$(dpkg --print-architecture)"; \\
    case "\${ARCH}" in \\
EOI
	print_java_install_pre ${file} ${bld} ${btype}
	if [ "${btype}" == "slim" ]; then
		print_ubuntu_slim_package $1
	fi
	print_java_install_post $1
}

# Print the main RUN command that installs Java on alpine.
print_alpine_java_install() {
	bld=$2
	btype=$3
	cat >> $1 <<-EOI
RUN set -eux; \\
    ARCH="\$(apk --print-arch)"; \\
    case "\${ARCH}" in \\
EOI
	print_java_install_pre ${file} ${bld} ${btype}
	if [ "${btype}" == "slim" ]; then
		print_alpine_slim_package $1
	fi
	print_java_install_post $1
}

# Print the JAVA_HOME and PATH.
# Currently Java is installed at a fixed path "/opt/java/openjdk"
print_java_env() {
	jhome="/opt/java/openjdk"

	cat >> $1 <<-EOI

ENV JAVA_HOME=${jhome} \\
    PATH="${jhome}/bin:\$PATH"
EOI
}

# Turn on JVM specific optimization flags.
# Hotspot container support = https://bugs.openjdk.java.net/browse/JDK-8189497
# OpenJ9 container support = https://www.eclipse.org/openj9/docs/xxusecontainersupport/
# OpenJ9 Idle tuning = https://www.eclipse.org/openj9/docs/xxidletuninggconidle/
print_java_options() {
	case ${vm} in
	hotspot)
		case ${version} in
		8|9)
			JOPTS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap";
			;;
		*)
			JOPTS="-XX:+UseContainerSupport";
			;;
		esac
		;;
	openj9)
		JOPTS="-XX:+IgnoreUnrecognizedVMOptions -XX:+UseContainerSupport -XX:+IdleTuningCompactOnIdle -XX:+IdleTuningGcOnIdle";
		;;
	esac

	cat >> $1 <<-EOI
ENV JAVA_TOOL_OPTIONS="${JOPTS}"
EOI
}

# For slim builds copy the slim script and related config files.
copy_slim_script() {
	if [ "${btype}" == "slim" ]; then
		cat >> $1 <<-EOI
COPY slim-java* /usr/local/bin/

EOI
	fi
}

# Generate the dockerfile for a given build, build_type and OS
generate_dockerfile() {
	file=$1
	bld=$2
	btype=$3
	os=$4
	mkdir -p `dirname ${file}` 2>/dev/null
	echo
	echo -n "Writing ${file} ... "
	print_legal ${file};
	print_${os}_ver ${file} ${bld} ${btype};
	print_maint ${file};
	print_${os}_pkg ${file};
	print_env ${file} ${bld} ${btype};
	copy_slim_script ${file};
	print_${os}_java_install ${file} ${bld} ${btype};
	print_java_env ${file} ${bld} ${btype};
	print_java_options ${file} ${bld} ${btype};
	echo "done"
	echo
}

# Print the FROM command for a specific java version
# This will be the base image for the build tool
print_base_java() {
	image_tag=$2

	repo="adoptopenjdk/openjdk${version}"
	if [ "${vm}" != "hotspot" ]; then
		repo="${repo}-${vm}";
	fi

	cat >> $1 <<-EOI
	FROM ${repo}:${image_tag}

	EOI
}

# Print the maven dockerfile install commands
print_maven() {
	cat >> $1 <<'EOI'

ARG MAVEN_VERSION="3.5.4"
ARG USER_HOME_DIR="/root"
ARG SHA="ce50b1c91364cb77efe3776f756a6d92b76d9038b0a0782f7d53acf1e997a14d"
ARG BASE_URL="https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries"

RUN mkdir -p /usr/share/maven \
    && curl -Lso  /tmp/maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && echo "${SHA}  /tmp/maven.tar.gz" | sha256sum -c - \
    && tar -xzC /usr/share/maven --strip-components=1 -f /tmp/maven.tar.gz \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "${USER_HOME_DIR}/.m2"

CMD ["/usr/bin/mvn"]
EOI
}

# Generate a build tool dockerfile for the given file and tag
generate_build_tool_dockerfile() {
	file=$1
	image_tag=$2

	mkdir -p `dirname ${file}` 2>/dev/null
	echo
	echo -n "Writing ${file} ... "

	print_legal ${file};
	print_base_java ${file} ${image_tag}
	print_maint ${file};
	print_${tool} ${file};
	echo "done"
	echo
}

# Create the build tools dockerfiles
function create_build_tool_dockerfiles() {
	vm=$1;
	os=$2;
	build=$3;
	btype=$4;

	# Get the tag alias to generate the build tools Dockerfiles
	build_tags ${vm} ${os} ${build} ${btype}
	# build_tags populates the array tag_aliases, but we just need the first element
	# The first element corresponds to the tag alias			
	tags_arr=(${tag_aliases});
	tag_alias=${tags_arr[0]};

	for tool in ${all_tools}
	do
		tool_dir=$(parse_config_file ${tool} ${version} ${os} "Directory:")
		file=${tool_dir}/Dockerfile.${vm}.${build}.${btype}
		generate_build_tool_dockerfile ${file} ${tag_alias}
	done
}
