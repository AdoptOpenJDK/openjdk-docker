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

ENV JAVA_VERSION jdk12u

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       aarch64|arm64) \
         ESUM='8a716facdba7ccbb39ed177bd195dc41deddf356ce68a240a268dc6786f3d06e'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk12u-2019-06-24-06-44/OpenJDK12U-jre_aarch64_linux_hotspot_2019-06-24-06-44.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='f0975d2c2d4d69e6ea3742b2c18d2e74662727445f42b4f057fc92ff617c82a3'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk12u-2019-06-24-06-44/OpenJDK12U-jre_x64_linux_hotspot_2019-06-24-06-44.tar.gz'; \
         ;; \
       s390x) \
         ESUM='e1e3c8c887eeaf36d6a5cd6670f1dc87c1e6d8f6e328f3467bd17b1b60f1a9ea'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk12u-2019-06-24-06-44/OpenJDK12U-jre_s390x_linux_hotspot_2019-06-24-06-44.tar.gz'; \
         ;; \
       ppc64el|ppc64le) \
         ESUM='11a0de37812be669b309c4d00ed57a19fa53237991463accf0d73e3709502bbc'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk12u-2019-06-24-06-44/OpenJDK12U-jre_ppc64le_linux_hotspot_2019-06-24-06-44.tar.gz'; \
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
