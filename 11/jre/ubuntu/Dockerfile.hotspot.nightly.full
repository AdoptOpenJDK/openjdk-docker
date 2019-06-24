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

ENV JAVA_VERSION jdk11u

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       aarch64|arm64) \
         ESUM='f91d981e9b6a788f296f26061598b32c310647a422e97d46602e9dadd13ca6eb'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk11u-2019-06-24-01-36/OpenJDK11U-jre_aarch64_linux_hotspot_2019-06-24-01-36.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='60c9dd3d894053543288535cc0afaa32c356e003aba260cda92b24e36d87c23f'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk11u-2019-06-24-01-36/OpenJDK11U-jre_x64_linux_hotspot_2019-06-24-01-36.tar.gz'; \
         ;; \
       s390x) \
         ESUM='3a78c406eb4b545283c2d30ea327805c3f5834cf4e96c7207bc919d9513cc830'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk11u-2019-06-24-01-36/OpenJDK11U-jre_s390x_linux_hotspot_2019-06-24-01-36.tar.gz'; \
         ;; \
       ppc64el|ppc64le) \
         ESUM='8c6acfd2e5972ac482c9917565817e2f7b6cc9d426faf023a007b36749986cee'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk11u-2019-06-24-01-36/OpenJDK11U-jre_ppc64le_linux_hotspot_2019-06-24-01-36.tar.gz'; \
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
