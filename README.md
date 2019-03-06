# OpenJDK and Docker
Dockerfiles and build scripts for generating various Docker Images related to OpenJDK. Currently this builds OpenJDK images with hotspot and Eclipse OpenJ9 on Ubuntu and Alpine Linux.

# Supported Architectures
* Hotspot is supported on ```aarch64```, ```ppc64le```, ```s390x``` and ```x86_64```.
* Eclipse OpenJ9 is supported on ```ppc64le```, ```s390x``` and ```x86_64```.

# License
The Dockerfiles and associated scripts found in this project are licensed under the [Apache License 2.0.](https://www.apache.org/licenses/LICENSE-2.0.html).

# Supported builds and build types
1. There are two kinds of build images
   * Release build images
     - These are release tested versions of the JDKs.
     - Associated tags: latest, alpine, ${version}
   * Nightly build images
     - These are nightly builds with minimal testing.
     - Associated tags: nightly, alpine-nightly, ${version}-nightly
2. There are two build types
   * Full build images
     - This consists of the full JDK.
     - Associated tags: latest, alpine, ${version}
   * Slim build images
     - These are stripped down JDK builds that remove functionality not typically needed while running in a cloud.
     - Associated tags: slim, alpine-slim, ${version}-slim

**Here is a listing of the image sizes for the various build images and types for JDK Version 8**

|Image|Description|Size
| --- | --- | ---
|adoptopenjdk/openjdk8:latest|8.jdk.hotspot.ubuntu.normal.releases|105
|adoptopenjdk/openjdk8:nightly|8.jdk.hotspot.ubuntu.normal.nightly|105
|adoptopenjdk/openjdk8:slim|8.jdk.hotspot.ubuntu.slim.releases|72
|adoptopenjdk/openjdk8:nightly-slim|8.jdk.hotspot.ubuntu.slim.nightly|72
|adoptopenjdk/openjdk8:alpine|8.jdk.hotspot.alpine.normal.releases|105
|adoptopenjdk/openjdk8:alpine-nightly|8.jdk.hotspot.alpine.normal.nightly|105
|adoptopenjdk/openjdk8:alpine-slim|8.jdk.hotspot.alpine.slim.releases|42
|adoptopenjdk/openjdk8:alpine-nightly-slim|8.jdk.hotspot.alpine.slim.nightly|42
|adoptopenjdk/openjdk8-openj9:latest|8.jdk.openj9.ubuntu.normal.releases|162
|adoptopenjdk/openjdk8-openj9:nightly|8.jdk.openj9.ubuntu.normal.nightly|162
|adoptopenjdk/openjdk8-openj9:slim|8.jdk.openj9.ubuntu.slim.releases|96
|adoptopenjdk/openjdk8-openj9:nightly-slim|8.jdk.openj9.ubuntu.slim.nightly|96
|adoptopenjdk/openjdk8-openj9:alpine|8.jdk.openj9.alpine.normal.releases|117
|adoptopenjdk/openjdk8-openj9:alpine-nightly|8.jdk.openj9.alpine.normal.nightly|117
|adoptopenjdk/openjdk8-openj9:alpine-slim|8.jdk.openj9.alpine.slim.releases|47
|adoptopenjdk/openjdk8-openj9:alpine-nightly-slim|8.jdk.openj9.alpine.slim.nightly|47
|adoptopenjdk/openjdk11:latest|11.jdk.hotspot.ubuntu.normal.releases|218
|adoptopenjdk/openjdk11:nightly|11.jdk.hotspot.ubuntu.normal.nightly|218
|adoptopenjdk/openjdk11:slim|11.jdk.hotspot.ubuntu.slim.releases|147
|adoptopenjdk/openjdk11:nightly-slim|11.jdk.hotspot.ubuntu.slim.nightly|147
|adoptopenjdk/openjdk11:alpine|11.jdk.hotspot.alpine.normal.releases|192
|adoptopenjdk/openjdk11:alpine-nightly|11.jdk.hotspot.alpine.normal.nightly|192
|adoptopenjdk/openjdk11:alpine-slim|11.jdk.hotspot.alpine.slim.releases|116
|adoptopenjdk/openjdk11:alpine-nightly-slim|11.jdk.hotspot.alpine.slim.nightly|117
|adoptopenjdk/openjdk11-openj9:latest|11.jdk.openj9.ubuntu.normal.releases|241
|adoptopenjdk/openjdk11-openj9:nightly|11.jdk.openj9.ubuntu.normal.nightly|242
|adoptopenjdk/openjdk11-openj9:slim|11.jdk.openj9.ubuntu.slim.releases|174
|adoptopenjdk/openjdk11-openj9:nightly-slim|11.jdk.openj9.ubuntu.slim.nightly|174
|adoptopenjdk/openjdk11-openj9:alpine|11.jdk.openj9.alpine.normal.releases|195
|adoptopenjdk/openjdk11-openj9:alpine-nightly|11.jdk.openj9.alpine.normal.nightly|195
|adoptopenjdk/openjdk11-openj9:alpine-slim|11.jdk.openj9.alpine.slim.releases|123
|adoptopenjdk/openjdk11-openj9:alpine-nightly-slim|11.jdk.openj9.alpine.slim.nightly|123
|adoptopenjdk/openjdk12:latest|12.jdk.hotspot.ubuntu.normal.releases|0
|adoptopenjdk/openjdk12:nightly|12.jdk.hotspot.ubuntu.normal.nightly|0
|adoptopenjdk/openjdk12:slim|12.jdk.hotspot.ubuntu.slim.releases|0
|adoptopenjdk/openjdk12:nightly-slim|12.jdk.hotspot.ubuntu.slim.nightly|0
|adoptopenjdk/openjdk12:alpine|12.jdk.hotspot.alpine.normal.releases|0
|adoptopenjdk/openjdk12:alpine-nightly|12.jdk.hotspot.alpine.normal.nightly|0
|adoptopenjdk/openjdk12:alpine-slim|12.jdk.hotspot.alpine.slim.releases|0
|adoptopenjdk/openjdk12:alpine-nightly-slim|12.jdk.hotspot.alpine.slim.nightly|0
|adoptopenjdk/openjdk12-openj9:latest|12.jdk.openj9.ubuntu.normal.releases|0
|adoptopenjdk/openjdk12-openj9:nightly|12.jdk.openj9.ubuntu.normal.nightly|0
|adoptopenjdk/openjdk12-openj9:slim|12.jdk.openj9.ubuntu.slim.releases|0
|adoptopenjdk/openjdk12-openj9:nightly-slim|12.jdk.openj9.ubuntu.slim.nightly|0
|adoptopenjdk/openjdk12-openj9:alpine|12.jdk.openj9.alpine.normal.releases|0
|adoptopenjdk/openjdk12-openj9:alpine-nightly|12.jdk.openj9.alpine.normal.nightly|0
|adoptopenjdk/openjdk12-openj9:alpine-slim|12.jdk.openj9.alpine.slim.releases|0
|adoptopenjdk/openjdk12-openj9:alpine-nightly-slim|12.jdk.openj9.alpine.slim.nightly|0


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
