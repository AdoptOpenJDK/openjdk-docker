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

COPY slim-java* /usr/local/bin/

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       ppc64el|ppc64le) \
         ESUM='a3541345178eb5a3bfae4ce38eb6e5ffab071c0c73bdaf7665dad4c805130c9e'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk9u-2018-09-30-13-10/OpenJDK9U_ppc64le_linux_openj9_2018-09-30-13-10.tar.gz'; \
         ;; \
       s390x) \
         ESUM='91653765327e90c64361972f000cd4345ec3e739afdf7564f2ea688251b97fc3'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk9u-2018-09-30-13-10/OpenJDK9U_s390x_linux_openj9_2018-09-30-13-10.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='e59c5832f45a454bfc1964039e4e18dc0834f67c0628aceff0373c0d6c526fbe'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk9u-2018-09-30-13-10/OpenJDK9U_x64_linux_openj9_2018-09-30-13-10.tar.gz'; \
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
    export PATH="/opt/java/openjdk/bin:$PATH"; \
    apt-get update; apt-get install -y --no-install-recommends binutils; \
    /usr/local/bin/slim-java.sh /opt/java/openjdk; \
    apt-get remove -y binutils; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf ${jdir} /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk \
    PATH="/opt/java/openjdk/bin:$PATH"
ENV JAVA_TOOL_OPTIONS="-XX:+IgnoreUnrecognizedVMOptions -XX:+UseContainerSupport -XX:+IdleTuningCompactOnIdle -XX:+IdleTuningGcOnIdle"
