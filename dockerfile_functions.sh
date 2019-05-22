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
	#      https://www.apache.org/licenses/LICENSE-2.0
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
	os_version="18.04"

	cat >> $1 <<-EOI
	FROM ubuntu:${os_version}

	EOI
}

# Print the supported Debian OS
print_debian_ver() {
	os_version="stretch"

	cat >> $1 <<-EOI
	FROM debian:${os_version}

	EOI
}

# Print the supported Windows OS
print_windows_ver() {
	os_version="ltsc2016"

	cat >> $1 <<-EOI
	FROM mcr.microsoft.com/windows/servercore:${os_version}

	EOI
}

# Print the supported Alpine OS
print_alpine_ver() {
	cat >> $1 <<-EOI
	FROM alpine:3.9

	EOI
}

# Print the locale and language
print_lang_locale() {
	cat >> $1 <<-EOI
	ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

	EOI
}

# Select the ubuntu OS packages
print_ubuntu_pkg() {
	cat >> $1 <<'EOI'
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*
EOI
}

print_debian_pkg() {
  print_ubuntu_pkg $1
}

print_windows_pkg() {
	cat >> $1 <<'EOI'

# $ProgressPreference: https://github.com/PowerShell/PowerShell/issues/2138#issuecomment-251261324
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
EOI
}

# Select the alpine OS packages.
# Install GNU glibc as this OpenJDK build is compiled against glibc and not musl.
print_alpine_pkg() {
	cat >> $1 <<'EOI'
RUN apk add --no-cache --virtual .build-deps curl binutils \
    && GLIBC_VER="2.29-r0" \
    && ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" \
    && GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-8.2.1%2B20180831-1-x86_64.pkg.tar.xz" \
    && GCC_LIBS_SHA256=e4b39fb1f5957c5aab5c2ce0c46e03d30426f3b94b9992b009d417ff2d56af4d \
    && ZLIB_URL="https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.11-3-x86_64.pkg.tar.xz" \
    && ZLIB_SHA256=17aede0b9f8baa789c5aa3f358fbf8c68a5f1228c5e6cba1a5dd34102ef4d4e5 \
    && curl -LfsS https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && SGERRAND_RSA_SHA256="823b54589c93b02497f1ba4dc622eaef9c813e6b0f0ebbb2f771e32adf9f4ef2" \
    && echo "${SGERRAND_RSA_SHA256} */etc/apk/keys/sgerrand.rsa.pub" | sha256sum -c - \
    && curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/glibc-${GLIBC_VER}.apk \
    && apk add /tmp/glibc-${GLIBC_VER}.apk \
    && curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk > /tmp/glibc-bin-${GLIBC_VER}.apk \
    && apk add /tmp/glibc-bin-${GLIBC_VER}.apk \
    && curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk > /tmp/glibc-i18n-${GLIBC_VER}.apk \
    && apk add /tmp/glibc-i18n-${GLIBC_VER}.apk \
    && /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true \
    && echo "export LANG=$LANG" > /etc/profile.d/locale.sh \
    && curl -LfsS ${GCC_LIBS_URL} -o /tmp/gcc-libs.tar.xz \
    && echo "${GCC_LIBS_SHA256} */tmp/gcc-libs.tar.xz" | sha256sum -c - \
    && mkdir /tmp/gcc \
    && tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc \
    && mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib \
    && strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* \
    && curl -LfsS ${ZLIB_URL} -o /tmp/libz.tar.xz \
    && echo "${ZLIB_SHA256} */tmp/libz.tar.xz" | sha256sum -c - \
    && mkdir /tmp/libz \
    && tar -xf /tmp/libz.tar.xz -C /tmp/libz \
    && mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib \
    && apk del --purge .build-deps glibc-i18n \
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
	pkg=$2
	bld=$3
	btype=$4
	reldir="openjdk${version}";
	if [ "${vm}" != "hotspot" ]; then
		reldir="${reldir}-${vm}";
	fi
	supported_arches=$(get_arches ${shasums})
	for sarch in ${supported_arches}
	do
		if [ "${sarch}" == "aarch64" ]; then
			JAVA_URL=$(get_v2_url info ${bld} ${vm} ${pkg} latest aarch64);
			cat >> $1 <<-EOI
       aarch64|arm64) \\
         ESUM='$(sarray=${shasums}[aarch64]; eval esum=\${$sarray}; echo ${esum})'; \\
         BINARY_URL='$(get_binary_url ${JAVA_URL})'; \\
         ;; \\
		EOI
	elif [ "${sarch}" == "armv7l" ]; then
			JAVA_URL=$(get_v2_url info ${bld} ${vm} ${pkg} latest arm);
			cat >> $1 <<-EOI
       armhf) \\
         ESUM='$(sarray=${shasums}[armv7l]; eval esum=\${$sarray}; echo ${esum})'; \\
         BINARY_URL='$(get_binary_url ${JAVA_URL})'; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "ppc64le" ]; then
			JAVA_URL=$(get_v2_url info ${bld} ${vm} ${pkg} latest ppc64le);
			cat >> $1 <<-EOI
       ppc64el|ppc64le) \\
         ESUM='$(sarray=${shasums}[ppc64le]; eval esum=\${$sarray}; echo ${esum})'; \\
         BINARY_URL='$(get_binary_url ${JAVA_URL})'; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "s390x" ]; then
			JAVA_URL=$(get_v2_url info ${bld} ${vm} ${pkg} latest s390x);
			cat >> $1 <<-EOI
       s390x) \\
         ESUM='$(sarray=${shasums}[s390x]; eval esum=\${$sarray}; echo ${esum})'; \\
         BINARY_URL='$(get_binary_url ${JAVA_URL})'; \\
         ;; \\
		EOI
		elif [ "${sarch}" == "x86_64" ]; then
			JAVA_URL=$(get_v2_url info ${bld} ${vm} ${pkg} latest x64);
			cat >> $1 <<-EOI
       amd64|x86_64) \\
         ESUM='$(sarray=${shasums}[x86_64]; eval esum=\${$sarray}; echo ${esum})'; \\
         BINARY_URL='$(get_binary_url ${JAVA_URL})'; \\
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
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
EOI
}

print_java_install_post() {
	cat >> $1 <<-EOI
    rm -rf /tmp/openjdk.tar.gz;
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

print_debian_slim_package() {
  print_ubuntu_slim_package $1
}

# Call the script to create the slim package for Alpine
# Install binutils for this phase as we need the "strip" command
# Uninstall once done
print_alpine_slim_package() {
	cat >> $1 <<-EOI
    export PATH="${jhome}/bin:\$PATH"; \\
    apk add --virtual .build-deps bash binutils; \\
    /usr/local/bin/slim-java.sh ${jhome}; \\
    apk del --purge .build-deps; \\
    rm -rf /var/cache/apk/*; \\
EOI
}

# Print the main RUN command that installs Java on ubuntu.
print_ubuntu_java_install() {
	pkg=$2
	bld=$3
	btype=$4
	cat >> $1 <<-EOI
RUN set -eux; \\
    ARCH="\$(dpkg --print-architecture)"; \\
    case "\${ARCH}" in \\
EOI
	print_java_install_pre ${file} ${pkg} ${bld} ${btype}
	if [ "${btype}" == "slim" ]; then
		print_ubuntu_slim_package $1
	fi
	print_java_install_post $1
}

print_debian_java_install() {
  print_ubuntu_java_install $1 $2 $3 $4
}

# Print the main RUN command that installs Java on ubuntu.
print_windows_java_install() {
	pkg=$2
	bld=$3
	btype=$4

	JAVA_URL=$(get_v2_url info ${bld} ${vm} ${pkg} latest windows-amd);

	ESUM=$(sarray=${shasums}[windows-amd]; eval esum=\${$sarray}; echo ${esum});
	BINARY_URL=$(get_instaler_url ${JAVA_URL});

	cat >> $1 <<-EOI
ENV JAVA_URL ${BINARY_URL}
ENV JAVA_SHA256 ${ESUM}

RUN Write-Host ('Downloading {0} ...' -f \$env:JAVA_URL); \\
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \\
        wget \$env:JAVA_URL -O 'openjdk.msi'; \\
        Write-Host ('Verifying sha256 ({0}) ...' -f \$env:JAVA_SHA256); \\
        if ((Get-FileHash openjdk.msi -Algorithm sha256).Hash -ne \$env:JAVA_SHA256) { \\
                Write-Host 'FAILED!'; \\
                exit 1; \\
        }; \\
        \\
        New-Item -ItemType Directory -Path C:\temp | Out-Null;

RUN Write-Host 'Installing using MSI ...'; \\
        Start-Process -FilePath "msiexec.exe" -ArgumentList '/i', 'openjdk.msi', '/L*V', 'C:\temp\OpenJDK.log', \\
        '/quiet', 'ADDLOCAL=FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome' -Wait -Passthru; \\
        Write-Host 'Removing ...'; \\
        Remove-Item openjdk.msi -Force;

RUN Write-Host 'Verifying install ...'; \\
        Write-Host '  java -version'; java -version; \\
        Write-Host '  javac -version'; javac -version; \\
        Write-Host '  JAVA_HOME'; Test-Path \$env:JAVA_HOME;
EOI
}

# Print the main RUN command that installs Java on alpine.
print_alpine_java_install() {
	pkg=$2
	bld=$3
	btype=$4
	cat >> $1 <<-EOI
RUN set -eux; \\
    apk add --virtual .fetch-deps curl; \\
    ARCH="\$(apk --print-arch)"; \\
    case "\${ARCH}" in \\
EOI
	print_java_install_pre ${file} ${pkg} ${bld} ${btype}
	if [ "${btype}" == "slim" ]; then
		print_alpine_slim_package $1
	fi
	cat >> $1 <<-EOI
    apk del --purge .fetch-deps; \\
    rm -rf /var/cache/apk/*; \\
EOI
	print_java_install_post $1
}

# Print the JAVA_HOME and PATH.
# Currently Java is installed at a fixed path "/opt/java/openjdk"
print_java_env() {
	# e.g 11 or 8
	version=$(echo $file | cut -f1 -d"/")
	os=$4
	if [ "$os" != "windows" ]; then
		cat >> $1 <<-EOI

ENV JAVA_HOME=${jhome} \\
    PATH="${jhome}/bin:\$PATH"
EOI
	fi
}

# Turn on JVM specific optimization flags.
# Hotspot container support = https://bugs.openjdk.java.net/browse/JDK-8189497
# OpenJ9 container support = https://www.eclipse.org/openj9/docs/xxusecontainersupport/
# OpenJ9 Idle tuning = https://www.eclipse.org/openj9/docs/xxidletuninggconidle/
print_java_options() {
	case ${vm} in
	hotspot)
		case ${version} in
		9)
			JOPTS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap";
			;;
		esac
		;;
	openj9)
		JOPTS="-XX:+IgnoreUnrecognizedVMOptions -XX:+UseContainerSupport -XX:+IdleTuningCompactOnIdle -XX:+IdleTuningGcOnIdle";
		;;
	esac

	if [ ! -z "${JOPTS}" ]; then
	cat >> $1 <<-EOI
ENV JAVA_TOOL_OPTIONS="${JOPTS}"
EOI
	fi
}

# For slim builds copy the slim script and related config files.
copy_slim_script() {
	if [ "${btype}" == "slim" ]; then
		cat >> $1 <<-EOI
COPY slim-java* /usr/local/bin/

EOI
	fi
}

print_cmd() {
	# for version > 8, set CMD["jshell"] in the Dockerfile
	above_8="^(9|[1-9][0-9]+)$"
	if [[ "${version}" =~ ${above_8} && "${package}" == "jdk" ]]; then
		cat >> $1 <<-EOI
		CMD ["jshell"]
		EOI
	fi
}

# Generate the dockerfile for a given build, build_type and OS
generate_dockerfile() {
	file=$1
	pkg=$2
	bld=$3
	btype=$4
	os=$5

	jhome="/opt/java/openjdk"

	mkdir -p `dirname ${file}` 2>/dev/null
	echo
	echo -n "Writing ${file} ... "
	print_legal ${file};
	print_${os}_ver ${file} ${bld} ${btype};
	print_lang_locale ${file};
	print_${os}_pkg ${file};
	print_env ${file} ${bld} ${btype};
	copy_slim_script ${file};
	print_${os}_java_install ${file} ${pkg} ${bld} ${btype};
	print_java_env ${file} ${bld} ${btype} ${os};
	print_java_options ${file} ${bld} ${btype};
	print_cmd ${file};
	echo "done"
	echo
}
