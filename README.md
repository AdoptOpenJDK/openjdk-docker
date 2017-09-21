# OpenJDK and Docker
Dockerfiles and build scripts for generating various Docker Images related to OpenJDK

# License
The Dockerfiles and associated scripts found in this project are licensed under the [Apache License 2.0.](http://www.apache.org/licenses/LICENSE-2.0.html).

# How it works

```
# Run ./generate_latest_sums.sh to get the shasums for the latest binaries available on adoptopenjdk.net
./generate_latest_sums.sh

# You should now have two files hotspot-shasums-latest.sh and openj9-shasums-latest.sh
# These will have the shasums for the latest version for each of the supported arches for hostpot and openj9

# You can now run update-multiarch.sh to generate the Dockerfiles for all supported arches for both hotspot and OpenJ9
./update-multiarch.sh

# build_latest.sh will do all of the above and build the docker images for the current arch with the right set of tags
./build_latest.sh
