# OpenJDK and Docker
Dockerfiles and build scripts for generating various Docker Images related to OpenJDK. Currently this builds OpenJDK images with hotspot and Eclipse OpenJ9 on Ubuntu and Alpine Linux.

# Supported Architectures
* Hotspot is supported on ```aarch64```, ```ppc64le```, ```s390x``` and ```x86_64```.
* Eclipse OpenJ9 is supported on ```ppc64le```, ```s390x``` and ```x86_64```.

# License
The Dockerfiles and associated scripts found in this project are licensed under the [Apache License 2.0.](http://www.apache.org/licenses/LICENSE-2.0.html).

# Build and push the Images with multi-arch support

```
# Steps 1-3 needs to be run on all supported arches.
# i.e aarch64, ppc64le, s390x and x86_64.

# 1. Clone this github repo
     $ git clone https://github.com/AdoptOpenJDK/openjdk-docker

# 2. Build images and tag them appropriately
     $ cd openjdk-docker
     $ ./build_latest.sh

# 3. The above script generates a script (push_commands.sh) that has the right commands to push to
#    hub.docker.com. Make sure to login to hub.docker first
     $ cat ~/my_password.txt | docker login --username foo --password-stdin
     $ ./push_commands.sh

# Steps 4-5 needs to be run only on x86_64

# 4. build_latest.sh and push_commands.sh should be run on all supported architectures to build and
#    push images to the docker registry. The images should now be available on hub.docker.com but
#    without multi-arch support. To add multi-arch support, we need to generate the right manifest
#    lists and push them to hub.docker.com. The script generate_manifest_script.sh can be used to
#    generate the right manifest commands. This needs to be run only on x86_64 after docker images
#    for all architecures have been built and made available on hub.docker.com
     $ ./generate_manifest_script.sh

# 5. generate_manifest_script.sh generates a script manifest-commands.sh, that creates the manifest
#    list and pushes them to hub.docker.com. 
     $ ./manifest-commands.sh

# We should now have the proper manifest lists pushed to hub.docker.com to support multi-arch pulls.
```

# Info on other scripts
```
# Run generate_latest_sums.sh to get the shasums for the latest binaries on adoptopenjdk.net
  $ ./generate_latest_sums.sh

# You should now have two files, hotspot-shasums-latest.sh and openj9-shasums-latest.sh. These will
# have the shasums for the latest version for each of the supported arches for hotspot and
# Eclipse OpenJ9 respectively.

# You can now run update-multiarch.sh to generate the Dockerfiles for all supported arches for both
# hotspot and Eclipse OpenJ9.
  $ ./update-multiarch.sh

# build_latest.sh will do all of the above and build the docker images for the current arch with the
# right set of tags
```
