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

ENV JAVA_VERSION jdk-10.0.2+13

COPY slim-java* /usr/local/bin/

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       ppc64el|ppc64le) \
         ESUM='f5c1b1476d588459d1edc03279025cce3aeaa464a4f28234cd18e8134e946954'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk10-binaries/releases/download/jdk-10.0.2%2B13/OpenJDK10U-jdk_ppc64le_linux_hotspot_10.0.2_13.tar.gz'; \
         ;; \
       s390x) \
         ESUM='54091b3d15086b4064aa2493fa578300751fc1b5b7e2028a8f8b889719f2a258'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk10-binaries/releases/download/jdk10u-2018-09-29-10-32/OpenJDK10U_s390x_linux_hotspot_2018-09-29-10-32.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='3998c36c7feb4bb7a565b3d33609ec67acd40f1ae5addf103378f2ef32ab377f'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk10-binaries/releases/download/jdk-10.0.2%2B13/OpenJDK10U-jdk_x64_linux_hotspot_10.0.2_13.tar.gz'; \
         ;; \
       aarch64|arm64) \
         ESUM='a4fc4e7a9204d6f450c71f0e82f3bf77571a6c52ae612227f99733848e893612'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk10-binaries/releases/download/jdk-10.0.2%2B13/OpenJDK10U-jdk_aarch64_linux_hotspot_10.0.2_13.tar.gz'; \
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
