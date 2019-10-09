[![Build Status](https://travis-ci.com/AdoptOpenJDK/openjdk-docker.svg?branch=master)](https://travis-ci.com/AdoptOpenJDK/openjdk-docker) [![Build status](https://ci.appveyor.com/api/projects/status/mlgtt6ndfb38y6ns/branch/master?svg=true)](https://ci.appveyor.com/project/gdams/openjdk-docker-k2x5l/branch/master)

# OpenJDK and Docker
Dockerfiles and build scripts for generating various Docker Images related to OpenJDK. Currently this builds OpenJDK images with hotspot and Eclipse OpenJ9 on Ubuntu and Alpine Linux.

# Supported Architectures
* Hotspot is supported on ```aarch64```, ```ppc64le```, ```s390x``` and ```x86_64```.
* Eclipse OpenJ9 is supported on ```ppc64le```, ```s390x``` and ```x86_64```.

## Mac OS X
Please note you'll need to [upgrade bash shell on Mac OS X](https://itnext.io/upgrading-bash-on-macos-7138bd1066ba) if you're to use our Docker images on there.

# License
The Dockerfiles and associated scripts found in this project are licensed under the [Apache License 2.0.](https://www.apache.org/licenses/LICENSE-2.0.html).

# Supported builds and build types

### Legend

   * ${os} = alpine|debian|ubi-minimal|ubuntu|windows
   * ${slim-os} = alpine|debian|ubuntu
   * ${jdk-version} Eg. jdk-11.0.3_7, jdk-12.33_openj9-0.13.0
   * ${jre-version} Eg. jre-11.0.3_7, jre-12.33_openj9-0.13.0

1. There are two kinds of build images
   * Release build images
     - These are release tested versions of the JDKs.
     - Associated tags:
     ```
       - latest, ${os},           ${jdk-version},      ${jdk-version}-${os}
       - jre,    ${os}-jre,       ${jre-version},      ${jre-version}-${os}
       - slim,   ${slim-os}-slim, ${jdk-version}-slim, ${jdk-version}-${slim-os}-slim
     ```
   * Nightly build images
     - These are nightly builds with minimal testing.
     - Associated tags:
     ```
       - nightly,      ${os}-nightly,           ${jdk-version}-${os}-nightly
       - jre-nightly,  ${os}-jre-nightly,       ${jre-version}-${os}-nightly
       - nightly-slim, ${slim-os}-nightly-slim, ${jdk-version}-${slim-os}-nightly-slim
     ```  
2. There are two build types
   * Full build images
     - This consists of the full JDK.
     - Associated tags:
     ```
       - latest,      ${os},             ${jdk-version},         ${jdk-version}-${os}
       - jre,         ${os}-jre,         ${jre-version},         ${jre-version}-${os}
       - nightly,     ${os}-nightly,     ${jdk-version}-nightly, ${jdk-version}-${os}-nightly
       - jre-nightly, ${os}-jre-nightly, ${jre-version}-nightly, ${jre-version}-${os}-nightly
     ```  
   * Slim build images
     - These are stripped down JDK builds that remove functionality not typically needed while running in a cloud. See the [./slim-java.sh](./slim-java.sh) script to see what is stripped out.
     - Associated tags:
     ```
       - slim,         ${slim-os}-slim,         ${jdk-version}-slim,         ${jdk-version}-${slim-os}-slim
       - nightly-slim, ${slim-os}-nightly-slim, ${jdk-version}-nightly-slim, ${jdk-version}-${slim-os}-nightly-slim
     ```  
3. There are also JDK and JRE only variants
   * JDK build images
     - This consists of the full JDK.
     - Associated tags:
     ```
       - latest,       ${os},                   ${jdk-version},              ${jdk-version}-${os}
       - slim,         ${slim-os}-slim,         ${jdk-version}-slim,         ${jdk-version}-${slim-os}-slim
       - nightly,      ${os}-nightly,           ${jdk-version}-nightly,      ${jdk-version}-${os}-nightly
       - nightly-slim, ${slim-os}-nightly-slim, ${jdk-version}-nightly-slim, ${jdk-version}-${slim-os}-nightly-slim
     ```  
   * JRE build images
     - This consists of only JRE.
     - Associated tags:
     ```
       - jre,         ${os}-jre,         ${jre-version},         ${jre-version}-${os}
       - jre-nightly, ${os}-jre-nightly, ${jre-version}-nightly, ${jre-version}-${os}-nightly
     ```

**Here is a listing of the image sizes for the various build images and types for JDK Version 8**

| VMs  | latest | slim | nightly | nightly-slim | alpine | alpine-slim | alpine-nightly | alpine-nightly-slim |
|:----:|:------:|:----:|:-------:|:------------:|:------:|:-----------:|:--------------:|:-------------------:|
|OpenJ9| 339MB  | 251MB|  344MB  |    250MB     | 208MB  |    120MB    |     213MB      |       118MB         |
|Hotspot| 324MB | 238MB|  324MB  |    238MB     | 193MB  |    106MB    |     193MB      |       106MB         |

**Notes:**
1. The alpine-slim images are about 60% smaller than the latest images.
2. The Alpine Linux and the slim images are not yet TCK certified.

# Build and push the Images with multi-arch support

```
# Steps 1-2 needs to be run on all supported arches.
# i.e aarch64, ppc64le, s390x and x86_64.

# 1. Clone this github repo
     $ git clone https://github.com/AdoptOpenJDK/openjdk-docker

# 2. Build images and tag them appropriately
     $ cd openjdk-docker
     $ ./build_all.sh

# Steps 3 needs to be run only on x86_64

# 3. build_all.sh should be run on all supported architectures to build and push images to the
#    docker registry. The images should now be available on hub.docker.com but without multi-arch
#    support. To add multi-arch support, we need to generate the right manifest lists and push them
#    to hub.docker.com. The script generate_manifest_script.sh can be used to
#    generate the right manifest commands. This needs to be run only on x86_64 after docker images
#    for all architecures have been built and made available on hub.docker.com
     $ ./update_manifest_all.sh

# We should now have the proper manifest lists pushed to hub.docker.com to support multi-arch pulls.
```
## Linting dockerfiles (via [hadolint](https://github.com/hadolint/hadolint))
To lint generated dockerfiles run [./linter.sh](./linter.sh) - script will download hadolint binary and check all dockerfiles.

# Info on other scripts
```
# Run generate_latest_sums.sh to get the shasums for the latest binaries on adoptopenjdk.net
  $ ./generate_latest_sums.sh $version

# You should now have two files, hotspot_shasums_latest.sh and openj9_shasums_latest.sh. These will
# have the shasums for the latest version for each of the supported arches for hotspot and
# Eclipse OpenJ9 respectively.

# You can now run update_multiarch.sh to generate the Dockerfiles for all supported arches for both
# hotspot and Eclipse OpenJ9.
  $ ./update_multiarch.sh $version

# build_latest.sh will do all of the above and build the docker images for the current arch with the
# right set of tags
```
