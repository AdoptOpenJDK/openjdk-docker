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

ENV JAVA_VERSION jdk-9.0.4+12_openj9-0.9.0

COPY slim-java* /usr/local/bin/

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       ppc64el|ppc64le) \
         ESUM='1e92e4386f8678bb80e38f32d8775bb211f3167e0287db1c96b521f567b9a00f'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk9-openj9-releases/releases/download/jdk-9.0.4%2B12_openj9-0.9.0/OpenJDK9-OPENJ9_ppc64le_Linux_jdk-9.0.4.12_openj9-0.9.0.tar.gz'; \
         ;; \
       s390x) \
         ESUM='6aa666a2408c6add59f2dc5585665388d6fbc66a39e34f6e48a9f450ab4311af'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk9-openj9-releases/releases/download/jdk-9.0.4%2B12_openj9-0.9.0/OpenJDK9-OPENJ9_s390x_Linux_jdk-9.0.4.12_openj9-0.9.0.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='d5bb41b7ed4fc1a6aba0914718aff4abec42acf18c776b7641efcbbb761e6e6b'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk9-openj9-releases/releases/download/jdk-9.0.4%2B12_openj9-0.9.0/OpenJDK9-OPENJ9_x64_Linux_jdk-9.0.4.12_openj9-0.9.0.tar.gz'; \
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
