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
       amd64|x86_64) \
         ESUM='f90b18c17296df32e3aa59556baa232fb0220dea0627fc6e1c91bd54fe4ef106'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk12u-2019-06-24-06-44/OpenJDK12U-jre_x64_linux_openj9_2019-06-24-06-44.tar.gz'; \
         ;; \
       s390x) \
         ESUM='690432bf5507a36724528e799c9446c3c4368aa23832cb483e3e01c119f2b758'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk12u-2019-06-24-06-44/OpenJDK12U-jre_s390x_linux_openj9_2019-06-24-06-44.tar.gz'; \
         ;; \
       ppc64el|ppc64le) \
         ESUM='ce0f742beffa361c898e6bf27d357924bfefa49fd8784dd7acb349e41dabc26e'; \
         BINARY_URL='https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk12u-2019-06-24-06-44/OpenJDK12U-jre_ppc64le_linux_openj9_2019-06-24-06-44.tar.gz'; \
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
ENV JAVA_TOOL_OPTIONS="-XX:+IgnoreUnrecognizedVMOptions -XX:+UseContainerSupport -XX:+IdleTuningCompactOnIdle -XX:+IdleTuningGcOnIdle"
