# ⚠ DEPRECATION NOTICE ⚠
These Dockerfiles along with their images are officially deprecated in favor of [the `eclipse-temurin` image](https://hub.docker.com/_/eclipse-temurin/), and will receive no further updates after 2021-08-25 (Aug 01, 2021). Please adjust your usage accordingly.

# AdoptOpenJDK and Docker
Dockerfiles and build scripts for generating Docker Images based on various AdoptOpenJDK binaries. We support both Hotspot and Eclipse OpenJ9 VMs.

# Supported Architectures
* Hotspot is supported on ```armv7l```, ```aarch64```, ```ppc64le```, ```s390x``` and ```x86_64```.
* Eclipse OpenJ9 is supported on ```ppc64le```, ```s390x``` and ```x86_64```.

# Supported OS

* Supported Linux OSes

| Alpine | centos | clefos | debian |  debianslim  | leap | tumbleweed | ubi | ubi-minimal | ubuntu(*) |
|:------:|:------:|:------:|:------:|:------------:|:----:|:----------:|:---:|:-----------:|:------:|
|  3.14  |    7   |    7   | buster | buster-slim  | 15.3 |   latest   | 8.4 |     8.4     |  20.04 |

Note: Hotspot is not supported on Ubuntu 20.04 for s390x arch.

* Supported Windows OSes
  - 1809
  - ltsc2016

# musl libc based Alpine Images

Starting from Java 16, hotspot builds are available natively built on musl libc instead of the regular glibc as part of the AdoptOpenJDK project. Currently these are available only for the x86_64 architecture. Accordingly we now have both regular and slim Docker Images for alpine musl based hotspot on x86_64.

# Official and Non-official Images
AdoptOpenJDK Docker Images are available as both Official Images (Maintained by Docker) and Non-official Images (Maintained by AdoptOpenJDK). Please choose based on your requirements.
* [Official Images](https://hub.docker.com/_/adoptopenjdk) are maintained by Docker and updated on every release from AdoptOpenJDK as well as when the underlying OSes are updated. Supported OSes and their versions and type of images are as below.
  - Linux
    - Ubuntu (20.04): Release
  - Windows
    - Windows Server Core (ltsc2016 and 1809): Release
* [Unofficial Images](https://hub.docker.com/u/adoptopenjdk) are maintained by AdoptOpenJDK and updated on a nightly basis. Supported OSes and their versions and type of images are as below.
  - Linux
    - Alpine (3.14): Release, Nightly and Slim
    - CentOS (7): Release, Nightly and Slim
    - ClefOS (7): Release, Nightly and Slim
    - Debian (Buster): Release, Nightly and Slim
    - DebianSlim (Buster-slim): Release, Nightly and Slim
    - Leap (15.3): Release and Nightly
    - Tumbleweed (latest): Release and Nightly
    - UBI (8.4): Release, Nightly and Slim
    - UBI-Minimal (8.4): Release and Nightly
    - Ubuntu (20.04): Nightly and Slim


## Unofficial Images: Docker Image Build Types and Associated Tags

### Legend

   * ${os} = alpine|debian|ubi|ubi-minimal|ubuntu|windows
   * ${slim-os} = alpine|debian|ubi|ubuntu
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

**Here is a listing of the image sizes for the various build images and types for JDK**

|Image|Description|Size
| --- | --- | --- 
|[adoptopenjdk/openjdk8:latest](8/jdk/ubuntu/Dockerfile.hotspot.releases.full)|8.jdk.hotspot.ubuntu.full.releases|107
|[adoptopenjdk/openjdk8:nightly](8/jdk/ubuntu/Dockerfile.hotspot.nightly.full)|8.jdk.hotspot.ubuntu.full.nightly|109
|[adoptopenjdk/openjdk8:slim](8/jdk/ubuntu/Dockerfile.hotspot.releases.slim)|8.jdk.hotspot.ubuntu.slim.releases|75
|[adoptopenjdk/openjdk8:nightly-slim](8/jdk/ubuntu/Dockerfile.hotspot.nightly.slim)|8.jdk.hotspot.ubuntu.slim.nightly|75
|[adoptopenjdk/openjdk8:alpine](8/jdk/alpine/Dockerfile.hotspot.releases.full)|8.jdk.hotspot.alpine.full.releases|105
|[adoptopenjdk/openjdk8:alpine-nightly](8/jdk/alpine/Dockerfile.hotspot.nightly.full)|8.jdk.hotspot.alpine.full.nightly|105
|[adoptopenjdk/openjdk8:alpine-slim](8/jdk/alpine/Dockerfile.hotspot.releases.slim)|8.jdk.hotspot.alpine.slim.releases|42
|[adoptopenjdk/openjdk8:alpine-nightly-slim](8/jdk/alpine/Dockerfile.hotspot.nightly.slim)|8.jdk.hotspot.alpine.slim.nightly|42
|[adoptopenjdk/openjdk8-openj9:latest](8/jdk/ubuntu/Dockerfile.openj9.releases.full)|8.jdk.openj9.ubuntu.full.releases|162
|[adoptopenjdk/openjdk8-openj9:nightly](8/jdk/ubuntu/Dockerfile.openj9.nightly.full)|8.jdk.openj9.ubuntu.full.nightly|163
|[adoptopenjdk/openjdk8-openj9:slim](8/jdk/ubuntu/Dockerfile.openj9.releases.slim)|8.jdk.openj9.ubuntu.slim.releases|97
|[adoptopenjdk/openjdk8-openj9:nightly-slim](8/jdk/ubuntu/Dockerfile.openj9.nightly.slim)|8.jdk.openj9.ubuntu.slim.nightly|97
|[adoptopenjdk/openjdk8-openj9:alpine](8/jdk/alpine/Dockerfile.openj9.releases.full)|8.jdk.openj9.alpine.full.releases|117
|[adoptopenjdk/openjdk8-openj9:alpine-nightly](8/jdk/alpine/Dockerfile.openj9.nightly.full)|8.jdk.openj9.alpine.full.nightly|117
|[adoptopenjdk/openjdk8-openj9:alpine-slim](8/jdk/alpine/Dockerfile.openj9.releases.slim)|8.jdk.openj9.alpine.slim.releases|47
|[adoptopenjdk/openjdk8-openj9:alpine-nightly-slim](8/jdk/alpine/Dockerfile.openj9.nightly.slim)|8.jdk.openj9.alpine.slim.nightly|47
|[adoptopenjdk/openjdk11:latest](11/jdk/ubuntu/Dockerfile.hotspot.releases.full)|11.jdk.hotspot.ubuntu.full.releases|221
|[adoptopenjdk/openjdk11:nightly](11/jdk/ubuntu/Dockerfile.hotspot.nightly.full)|11.jdk.hotspot.ubuntu.full.nightly|221
|[adoptopenjdk/openjdk11:slim](11/jdk/ubuntu/Dockerfile.hotspot.releases.slim)|11.jdk.hotspot.ubuntu.slim.releases|149
|[adoptopenjdk/openjdk11:nightly-slim](11/jdk/ubuntu/Dockerfile.hotspot.nightly.slim)|11.jdk.hotspot.ubuntu.slim.nightly|149
|[adoptopenjdk/openjdk11:alpine](11/jdk/alpine/Dockerfile.hotspot.releases.full)|11.jdk.hotspot.alpine.full.releases|192
|[adoptopenjdk/openjdk11:alpine-nightly](11/jdk/alpine/Dockerfile.hotspot.nightly.full)|11.jdk.hotspot.alpine.full.nightly|193
|[adoptopenjdk/openjdk11:alpine-slim](11/jdk/alpine/Dockerfile.hotspot.releases.slim)|11.jdk.hotspot.alpine.slim.releases|116
|[adoptopenjdk/openjdk11:alpine-nightly-slim](11/jdk/alpine/Dockerfile.hotspot.nightly.slim)|11.jdk.hotspot.alpine.slim.nightly|117
|[adoptopenjdk/openjdk11-openj9:latest](11/jdk/ubuntu/Dockerfile.openj9.releases.full)|11.jdk.openj9.ubuntu.full.releases|242
|[adoptopenjdk/openjdk11-openj9:nightly](11/jdk/ubuntu/Dockerfile.openj9.nightly.full)|11.jdk.openj9.ubuntu.full.nightly|242
|[adoptopenjdk/openjdk11-openj9:slim](11/jdk/ubuntu/Dockerfile.openj9.releases.slim)|11.jdk.openj9.ubuntu.slim.releases|174
|[adoptopenjdk/openjdk11-openj9:nightly-slim](11/jdk/ubuntu/Dockerfile.openj9.nightly.slim)|11.jdk.openj9.ubuntu.slim.nightly|174
|[adoptopenjdk/openjdk11-openj9:alpine](11/jdk/alpine/Dockerfile.openj9.releases.full)|11.jdk.openj9.alpine.full.releases|195
|[adoptopenjdk/openjdk11-openj9:alpine-nightly](11/jdk/alpine/Dockerfile.openj9.nightly.full)|11.jdk.openj9.alpine.full.nightly|195
|[adoptopenjdk/openjdk11-openj9:alpine-slim](11/jdk/alpine/Dockerfile.openj9.releases.slim)|11.jdk.openj9.alpine.slim.releases|123
|[adoptopenjdk/openjdk11-openj9:alpine-nightly-slim](11/jdk/alpine/Dockerfile.openj9.nightly.slim)|11.jdk.openj9.alpine.slim.nightly|123
|[adoptopenjdk/openjdk12:latest](12/jdk/ubuntu/Dockerfile.hotspot.releases.full)|12.jdk.hotspot.ubuntu.full.releases|232
|[adoptopenjdk/openjdk12:nightly](12/jdk/ubuntu/Dockerfile.hotspot.nightly.full)|12.jdk.hotspot.ubuntu.full.nightly|231
|[adoptopenjdk/openjdk12:slim](12/jdk/ubuntu/Dockerfile.hotspot.releases.slim)|12.jdk.hotspot.ubuntu.slim.releases|158
|[adoptopenjdk/openjdk12:nightly-slim](12/jdk/ubuntu/Dockerfile.hotspot.nightly.slim)|12.jdk.hotspot.ubuntu.slim.nightly|158
|[adoptopenjdk/openjdk12:alpine](12/jdk/alpine/Dockerfile.hotspot.releases.full)|12.jdk.hotspot.alpine.full.releases|203
|[adoptopenjdk/openjdk12:alpine-nightly](12/jdk/alpine/Dockerfile.hotspot.nightly.full)|12.jdk.hotspot.alpine.full.nightly|203
|[adoptopenjdk/openjdk12:alpine-slim](12/jdk/alpine/Dockerfile.hotspot.releases.slim)|12.jdk.hotspot.alpine.slim.releases|126
|[adoptopenjdk/openjdk12:alpine-nightly-slim](12/jdk/alpine/Dockerfile.hotspot.nightly.slim)|12.jdk.hotspot.alpine.slim.nightly|126
|[adoptopenjdk/openjdk12-openj9:latest](12/jdk/ubuntu/Dockerfile.openj9.releases.full)|12.jdk.openj9.ubuntu.full.releases|243
|[adoptopenjdk/openjdk12-openj9:nightly](12/jdk/ubuntu/Dockerfile.openj9.nightly.full)|12.jdk.openj9.ubuntu.full.nightly|243
|[adoptopenjdk/openjdk12-openj9:slim](12/jdk/ubuntu/Dockerfile.openj9.releases.slim)|12.jdk.openj9.ubuntu.slim.releases|174
|[adoptopenjdk/openjdk12-openj9:nightly-slim](12/jdk/ubuntu/Dockerfile.openj9.nightly.slim)|12.jdk.openj9.ubuntu.slim.nightly|174
|[adoptopenjdk/openjdk12-openj9:alpine](12/jdk/alpine/Dockerfile.openj9.releases.full)|12.jdk.openj9.alpine.full.releases|196
|[adoptopenjdk/openjdk12-openj9:alpine-nightly](12/jdk/alpine/Dockerfile.openj9.nightly.full)|12.jdk.openj9.alpine.full.nightly|196
|[adoptopenjdk/openjdk12-openj9:alpine-slim](12/jdk/alpine/Dockerfile.openj9.releases.slim)|12.jdk.openj9.alpine.slim.releases|123
|[adoptopenjdk/openjdk12-openj9:alpine-nightly-slim](12/jdk/alpine/Dockerfile.openj9.nightly.slim)|12.jdk.openj9.alpine.slim.nightly|123






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

# Info on other scripts
 - [update_all.sh](/update_all.sh): Script to generate all Dockerfiles.
   - [update_multiarch.sh](/update_multiarch.sh): Helper script that generates Dockerfiles for a specific Java version.
   ```
     $ ./update_multiarch.sh $version
   ```
   - [dockerfile_functions.sh](/dockerfile_functions.sh): Dockerfile content is generated from this. Update this script if you want any changes to the generated Dockerfiles.
 - [build_all.sh](/build_all.sh): Script to build all supported unofficial docker images on a particular architecture.
   - [build_latest.sh](/build_latest.sh): Helper script that builds a docker image for a specific Java version, VM and package combination.
 
 - [update_manifest_all.sh](/update_manifest_all.sh): Script that generates the multi-arch manifest for all unofficial docker images for supported/released architectures at any given time.
   - [generate_manifest_script.sh](/generate_manifest_script.sh): Helper script that generates the manifest for a given Java version, VM and Package combination for all supported architectures. If a build is unavailable for a supported architecture (build failed, not yet released etc), a manifest entry for that architecture will not be added.

 - [linter.sh](/linter.sh): Linting dockerfiles (via [hadolint](https://github.com/hadolint/hadolint)). 
   ```
    To lint generated dockerfiles run 
    $ ./linter.sh
   ```
#### Helper Scripts

 - Run [generate_latest_sums.sh](/generate_latest_sums.sh) to get the shasums for the latest binaries on adoptopenjdk.net
   ```
    $ ./generate_latest_sums.sh $version
   ```
   You should now have two files, `hotspot_shasums_latest.sh` and `openj9_shasums_latest.sh`. These will have the shasums for the latest version for each of the supported arches for hotspot and Eclipse OpenJ9 respectively.
 - [slim-java.sh](/slim-java.sh): Script that is used to generate the slim docker images. This script strips out various aspects of the JDK that are typically not needed in a server side containerized application. This includes debug info, symbols, classes related to audio, desktop etc
 - [slim-java.ps1](/slim-java.ps1): Script that is used to generate slim docker images on Windows. This script provides the same function as the slim-java.sh script mentioned above.
 - [dockerhub_doc_config_update.sh](/dockerhub_doc_config_update.sh): Script that generates the tag documentation for each of the unofficial AdoptOpenJDK pages on hub.docker.com and the config file for raising a PR at the Official AdoptOpenJDK git repo.

#### Config Files

The [config](/config/) dir consists of configuration files used by the scripts to determine the supported combinations of Version / OS / VM / Package / Build types and Architectures for both Official/Unofficial images as well as the corresponding tags.
- [hotspot.config](/config/hotspot.config): Configuration for unofficial images for HotSpot.
- [hotspot-official.config](/config/hotspot-official.config): Configuration for official images for HotSpot.
- [openj9.config](/config/openj9.config): Configuration for unofficial images for Eclipse OpenJ9.
- [openj9-official.config](/config/openj9-official.config): Configuration for official images for Eclipse OpenJ9.
- [tags.config](/config/tags.config): Configuration for creating tags.

## Mac OS X
Please note you'll need to [upgrade bash shell on Mac OS X](https://itnext.io/upgrading-bash-on-macos-7138bd1066ba) if you're to use our Docker images on there.

# License
The Dockerfiles and associated scripts found in this project are licensed under the [Apache License 2.0.](https://www.apache.org/licenses/LICENSE-2.0.html).
