# ------------------------------------------------------------------------------
#               NOTE: THIS DOCKERFILE IS GENERATED VIA "build_latest.sh" or "update_multiarch.sh"
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

FROM centos:7

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN yum install -y tzdata openssl curl ca-certificates fontconfig gzip tar \
    && yum update -y; yum clean all

ENV JAVA_VERSION jdk-14.0.2+12_openj9-0.21.0

RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "${ARCH}" in \
       ppc64el|ppc64le) \
         ESUM='177fd161ae14df92203d70cd618559daf889ec0c172d6ee615859352f68a2371'; \
         BINARY_URL=''; \
         ;; \
       s390x) \
         ESUM='4757dc2009a0c31604be4631e02a5a3aac53ebe9b6a2046ae8995ec0e453dc1a'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk14-binaries/releases/download/jdk-14.0.2%2B12_openj9-0.21.0/OpenJDK14U-jdk_s390x_linux_openj9_14.0.2_12_openj9-0.21.0.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='306f7138cdb65daaf2596ec36cafbde72088144c83b2e964f0193662e6caf3be'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk14-binaries/releases/download/jdk-14.0.2%2B12_openj9-0.21.0/OpenJDK14U-jdk_x64_linux_openj9_14.0.2_12_openj9-0.21.0.tar.gz'; \
         ;; \
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
    rm -rf /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk \
    PATH="/opt/java/openjdk/bin:$PATH"
ENV JAVA_TOOL_OPTIONS="-XX:+IgnoreUnrecognizedVMOptions -XX:+UseContainerSupport -XX:+IdleTuningCompactOnIdle -XX:+IdleTuningGcOnIdle"
CMD ["jshell"]
