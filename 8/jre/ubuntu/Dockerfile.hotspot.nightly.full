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
         ESUM='cc7a188efc5015d61114d053717e8fdcdabe5f2760c255a4095775160460d87e'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2019-06-24-02-58/OpenJDK8U-jre_aarch64_linux_hotspot_2019-06-24-02-58.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='2ee8517e9bb6a2862e981781cbe3ba0d0302e4649003f21ade9889b18bdf004f'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2019-06-24-02-58/OpenJDK8U-jre_x64_linux_hotspot_2019-06-24-02-58.tar.gz'; \
         ;; \
       s390x) \
         ESUM='75415decd7bfccc913ceeaea32f5bbb4a45930869db6bb588c236cf7290bea03'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2019-06-24-02-58/OpenJDK8U-jre_s390x_linux_hotspot_2019-06-24-02-58.tar.gz'; \
         ;; \
       ppc64el|ppc64le) \
         ESUM='6bf1d3650b7859a933810ec335b088d0aee065fb6de5395f87cfd13c12240a8b'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u-2019-06-24-02-58/OpenJDK8U-jre_ppc64le_linux_hotspot_2019-06-24-02-58.tar.gz'; \
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
