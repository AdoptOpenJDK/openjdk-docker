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

FROM debian:stretch

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates locales \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_VERSION jdk11u

COPY slim-java* /usr/local/bin/

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       aarch64|arm64) \
         ESUM='efd333adf395c3f972b012d3baa26ab58431eaebee0d23e633a9c698ce6b5e80'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk11u-2019-06-24-01-36/OpenJDK11U-jdk_aarch64_linux_hotspot_2019-06-24-01-36.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='a8d2449b7424f516857bf0c8dc76de22c4592adb36268bc1820d52301aebe3c6'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk11u-2019-06-24-01-36/OpenJDK11U-jdk_x64_linux_hotspot_2019-06-24-01-36.tar.gz'; \
         ;; \
       armhf) \
         ESUM='a2634a347b08d9b89659884f6e91d56a76c9d5deeddee52bb4804a96ec9b1dc4'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk11u-2019-06-24-01-36/OpenJDK11U-jdk_arm_linux_hotspot_2019-06-24-01-36.tar.gz'; \
         ;; \
       s390x) \
         ESUM='b3ed18935f91dc39766aef0e17f13280164abaa37f1cdcf8798cdecb910904a5'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk11u-2019-06-24-01-36/OpenJDK11U-jdk_s390x_linux_hotspot_2019-06-24-01-36.tar.gz'; \
         ;; \
       ppc64el|ppc64le) \
         ESUM='6f177acbbf48e15f28e137c2d04ef75dedde18ae64355ded2b8c456b2e245599'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk11u-2019-06-24-01-36/OpenJDK11U-jdk_ppc64le_linux_hotspot_2019-06-24-01-36.tar.gz'; \
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
    export PATH="/opt/java/openjdk/bin:$PATH"; \
    apt-get update; apt-get install -y --no-install-recommends binutils; \
    /usr/local/bin/slim-java.sh /opt/java/openjdk; \
    apt-get remove -y binutils; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk \
    PATH="/opt/java/openjdk/bin:$PATH"
CMD ["jshell"]
