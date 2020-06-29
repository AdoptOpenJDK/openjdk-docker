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

ENV JAVA_VERSION jdk9u

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       ppc64el|ppc64le) \
         ESUM='b1d517a7ee0fbd919d75a097dfac862ace9dc61b4ff04ca955fd9afb58602cad'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk9u-2018-09-30-13-10/OpenJDK9U_ppc64le_linux_hotspot_2018-09-30-13-10.tar.gz'; \
         ;; \
       s390x) \
         ESUM='0343b8cc3e77def041c2d0cd024b55d763503586463365f7f1d6139648fa96b1'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk9u-2018-09-30-13-10/OpenJDK9U_s390x_linux_hotspot_2018-09-30-13-10.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='92a220a2e77a210e93126b3c867ecfe22fdabea326c151cb175db0176c854b4a'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk9u-2018-09-30-13-10/OpenJDK9U_x64_linux_hotspot_2018-09-30-13-10.tar.gz'; \
         ;; \
       aarch64|arm64) \
         ESUM='15d4b558189af975d0fdbcb0919e7637e42d79f0b1352f14975fed8f3d47dc39'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk9u-2018-09-30-13-10/OpenJDK9U_aarch64_linux_hotspot_2018-09-30-13-10.tar.gz'; \
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
ENV JAVA_TOOL_OPTIONS="-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"
