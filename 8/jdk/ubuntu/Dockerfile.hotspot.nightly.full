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

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates locales \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_VERSION jdk8u

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       aarch64|arm64) \
         ESUM='cd69817cb0218d2e9d5c445b076a77933426219c02985a53d1cbbd27aa02fe51'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2019-06-24-02-58/OpenJDK8U-jdk_aarch64_linux_hotspot_2019-06-24-02-58.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='93c37a9180f8167821b7b98985bbb00298a81d6847cdea0bca9a15aef16ae49d'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2019-06-24-02-58/OpenJDK8U-jdk_x64_linux_hotspot_2019-06-24-02-58.tar.gz'; \
         ;; \
       s390x) \
         ESUM='b16901ef21627f953e98644b0b2197d56e8c22e1c461df88d97219fb2adfff8a'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2019-06-24-02-58/OpenJDK8U-jdk_s390x_linux_hotspot_2019-06-24-02-58.tar.gz'; \
         ;; \
       ppc64el|ppc64le) \
         ESUM='127e9d0fed4e1efd904aa284abc128fa04a7c7f4f3370ba2078e3bcd91ace706'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2019-06-24-02-58/OpenJDK8U-jdk_ppc64le_linux_hotspot_2019-06-24-02-58.tar.gz'; \
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
