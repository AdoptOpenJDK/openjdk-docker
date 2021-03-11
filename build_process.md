# Build process

The `build` process can be triggered by running the script `build_all.sh` 

The number of docker images that are created are based on the combination of 
 
`version` \
`vm type` (Hotspot, OpenJ9) \
`package` (JDK, JRE) \
`os` \
`build type` (Release, Nightly) \
`package type` (slim, full)

### Workflow

##### Step - 1:

`build_all.sh` loops over the `version` , `vm type` and `package`, triggers `build_latest.sh` 
to build image for the supported `os`

The config files for each vm type are available in the repo (Eg. opej9.config, hotspot.config). 
The script parses the entries wrt to the `version` , `vm type` and `os` to get the config details 
like `build type` , `Directory to create dockerfiles` and `package type`

##### Step - 2:

For each `build type` and `package type` we create the dockerfile and build the docker images

First we will get the shasums for the given combination, the `get_shasums` function loads the 
existing shasums if the file exists (wrt vm type, for hotspot - hotspot_shasums_latest.sh), Else 
it creates the file declaring the shasums for each combination by getting them from adoptopenjdk

##### Step - 3:

Based on the OS and build type the dockerfile is generated based on the conditions placed in
`dockerfile_functions.sh` (Eg. Packages needed to be installed, downloading the adoptopenjdk 
tar and extracting it to the location, cleaning up the package manager caches) once the file
is generated its checks if the build is required and it needs the docker image is generated 
and pushed to adopt docker repo
