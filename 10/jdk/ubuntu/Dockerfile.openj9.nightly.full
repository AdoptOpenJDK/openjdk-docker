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

FROM ubuntu:18.04

LABEL maintainer="dinakar.g@in.ibm.com"

RUN rm -rf /var/lib/apt/lists/* && apt-get clean && apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_VERSION jdk10u

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       ppc64el|ppc64le) \
         ESUM='e529ed62a88c944b247a1e0bc522a7ce613ba1e4b6df45219acfd4ddc7af7f03'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk10-binaries/releases/download/jdk10u-2018-09-29-10-32/OpenJDK10U_ppc64le_linux_openj9_2018-09-29-10-32.tar.gz'; \
         ;; \
       s390x) \
         ESUM='7a364d9d5c4c0452f4f50c23ac24bf1a3eb5ee52733f0f46c1214947533d114f'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk10-binaries/releases/download/jdk10u-2018-09-26-18-22/OpenJDK10U_s390x_linux_openj9_2018-09-26-18-22.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='e980fbe5f71fdf66c368f4c88efebd191df0cb7114f3702b6ab83976ca994554'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk10-binaries/releases/download/jdk10u-2018-09-29-10-32/OpenJDK10U_x64_linux_openj9_2018-09-29-10-32.tar.gz'; \
         ;; \
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    curl -Lso /tmp/openjdk.tar.gz ${BINARY_URL}; \
    sha256sum /tmp/openjdk.tar.gz; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    echo "${ESUM}  /tmp/openjdk.tar.gz" | sha256sum -c -; \
    tar -xf /tmp/openjdk.tar.gz; \
    jdir=$(dirname $(dirname $(find /opt/java/openjdk -name javac))); \
    mv ${jdir}/* /opt/java/openjdk; \
    rm -rf ${jdir} /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk \
    PATH="/opt/java/openjdk/bin:$PATH"
ENV JAVA_TOOL_OPTIONS="-XX:+IgnoreUnrecognizedVMOptions -XX:+UseContainerSupport -XX:+IdleTuningCompactOnIdle -XX:+IdleTuningGcOnIdle"
