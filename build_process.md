# Build process

The `build` process can be triggered by running the script `build_all.sh` 

The number of docker images that are created are based on the combination of 
 
`version` \
`vm type` (Hotspot, OpenJ9) \
`package` (JDK, JRE) \
`os` \
`build type` (Release, Nightly) \
`package type` (slim, full)

## Workflow

### Step - 1:

`build_all.sh` loops over the `version` , `vm type` and `package`, triggers `build_latest.sh` 
to build image for the supported `os`

The config files for each vm type are available in the repo (Eg. opej9.config, hotspot.config). 
The script parses the entries wrt to the `version` , `vm type` and `os` to get the config details 
like `build type` , `Directory to create dockerfiles` and `package type`

#### Flow
**Loop 1:** `for ver in ${supported_versions}`

This loop iterates over the supported versions which are specified in `common_functions.sh` file.

`export supported_versions="8 11 14 15 16"`

**Loop 2:** `for vm in ${all_jvms}`

This loop iterates over the jvm variants available, specified in `common_functions.sh`

`all_jvms="hotspot openj9"`

**Loop 3:** `for package in ${all_packages}`

This loop iterates over the package types specified in `common_functions.sh`

`all_packages="jdk jre"`

- Now we clean the images and manifests which are generated in the previous build by the functions

`cleanup_images` and `cleanup_manifest` (available in `common_functions.sh`)

- We remove the temporary files generated in the previous build by 

`rm -f hotspot_*_latest.sh openj9_*_latest.sh push_commands.sh`

- Now we build the images for the specific version, vm type & package, by calling the `build_latest.sh` script and passing these values as arguments.

`./build_latest.sh "${ver}" "${vm}" "${package}" "${runtype}"`

**NOTE:** `runtype` is added to make some image builds disabled in PR checks. `runtype` can either be a `build` or `test`. In `build` all the images are generated but in `test` only specific images are generated as part of PR checks.


- In `build_latest.sh` we first get the OS's supported on the current architecture, we get it via `set_arch_os` which is specified in `common_functions.sh`. We set 3 vars based on the architecture of the machine

`current_arch` - holds the value of current architecture of the machine [eg: armv7l, aarch64, s390x etc]

`oses` - holds the list of supported os for the architecture

`os_family` - windows/linux

- We iterate over the OS list and the builds and build type from the config files based on the version and vm info by `parse_vm_entry` function (available in `common_functions.sh`)

```
    # Build = Release or Nightly
    builds=$(parse_vm_entry "${vm}" "${version}" "${package}" "${os}" "Build:")
    # Type = Full or Slim
    btypes=$(parse_vm_entry "${vm}" "${version}" "${package}" "${os}" "Type:")
```

- We generate the dockerfiles in specific directories based on the version, os, variant (JDK/JRE) and that location is extracted from config files by `parse_vm_entry` function (available in `common_functions.sh`)

`dir=$(parse_vm_entry "${vm}" "${version}" "${package}" "${os}" "Directory:")`

- Now we iterate over the `builds` list which we extracted from the config files

`for build in ${builds}`

- For each build we get the shasums by calling `get_shasums` function in `common_functions.sh` and store them in a script depending on the vm type. These are temporary files which are deleted at the start of the build process.

`get_shasums "${version}" "${vm}" "${package}" "${build}"`

- Now we iterate over the build types for each build in the list (earlier iteration `builds`)

`for btype in ${btypes}`

### Step - 2:

For each `build type` and `package type` we create the dockerfile and build the docker images

First we will get the shasums for the given combination, the `get_shasums` function loads the 
existing shasums if the file exists (wrt vm type, for hotspot - hotspot_shasums_latest.sh), Else 
it creates the file declaring the shasums for each combination by getting them from adoptopenjdk

#### Flow

- We now generate the dockerfile calling `generate_dockerfile` function in `dockerfile_functions.sh` based on the vars 
  
`file` - Location of the dockerfile
`package` - JDK/JRE
`build` - release/nightly
`btype` - full/slim
`os` - os variant for which the dockerfile is getting generated

`generate_dockerfile "${file}" "${package}" "${build}" "${btype}" "${os}"`

- Next we write the dockerfile based on the passed args, we make it step by step like first we write the legal header to the file by calling the function `print_legal`

`print_legal` - Adds legal information on the top of the dockerfile

- Next we add the base OS version by calling the appropriate functions based on the `os_family` variable

`print_${os_family}_ver` - Adds OS information to the dockerfile

(`print_ubuntu_ver`, `print_alpine_ver`, `print_centos_ver` etc)

Eg: 

```
FROM ubuntu:20.04
```

- Next we add the language locales with function `print_lang_locale`

- We now install the necessary packages required by calling appropriate functions based on the `os_family` variable

`print_${os_family}_pkg` - Adds the package installations wrt os and their default package managers

(`print_ubuntu_pkg`, `print_alpine_pkg`, `print_centos_pkg` etc)

- We now declare the `LABEL` in the dockerfile, by calling the `print_env` function

`print_env` - Adds the environment info (LABEL) to the dockerfile

- We now proceed to copy slim script if it's a slim build by calling the function `copy_slim_script`

- Next step is to install java,  so we now call the appropriate java installation function which describes the URL location and shasums based on the system architecture, It downloads the tarball installs it and removes the downloaded tarball

`print_"${os_family}"_java_install` - Installs java based on the `os_family`

`print_java_install_pre` & `print_java_install_post` are the other two functions called to download, extract, install and delete the tarball

- Next step we will add the environment vars to the dockerfile, Like `JAVA_HOME` and `PATH` by calling the `print_java_env` function

`print_java_env` - Adds the environment vars `JAVA_HOME` and `PATH` to the dockerfile

- Next we add the Java Options to the dockerfile based on the type of VM (Hotspot / OpenJ9)

`print_java_options` - Adds VM specific java options like (`-Xshareclasses` in OpenJ9 etc)

- We now proceed to SCC (Shared Class Cache) generation step if it's a linux environment

`print_scc_gen` - Installs tomcat and starts it with `-Xshareclasses` set to default location and size (`50M`) and now we extract the original size of SCC for baseclasses, destroy the cache and re-run the tomcat with right size and saves the cache as part of the image.

- Finally we now add the executing command at the bottom of the dockerfile by calling `print_cmd`

`print_cmd` - Sets `CMD` as `jshell` to get executed when the container starts.

- Next we go ahead and build the docker image from the file generated

### Step - 3:

Based on the OS and build type the dockerfile is generated based on the conditions placed in
`dockerfile_functions.sh` (Eg. Packages needed to be installed, downloading the adoptopenjdk 
tar and extracting it to the location, cleaning up the package manager caches) once the file is generated its checks if the build is required and it needs
the docker image is generated and pushed to adopt docker repo

- After the dockerfile is generated we check of the file is generated and we proceed to docker image building by calling the function `build_dockerfile` in `build_latest.sh`

`build_dockerfile "${vm}" "${package}" "${build}" "${btype}" "${osfamily}" "${os}"`

- We now set the tag, repo etc from the vars passed to the function

`trepo` - will be the combination of `target_repo` and `version`. if its openj9 the `-openj9` is added at the end
`tag` -  will be the combination of `current_arch` , `os`, `release`, `package_type`, `build_type`

- If it's a slim build then we copy the `slim-java.sh` and `config` files to the respective directory where the docker build is issued to make them available in docker context

- Now we build the image by calling the `build_image` function

`build_image "${trepo}" "${build}" "${btype}" "${osfamily}" "${tag}"`

- First we check if the build is needed by calling the `check_build_needed` function. 

`check_build_needed "${dockerfile}" "${osfamily}" "${image_name}"`

- We proceed to build only if the latest build (tarball) is available at adopt and adopt image is created 24 hours before the time of adopt build.

`check_new_adopt_build_available` - Checks if new adopt tarball is available and gets the creation time of docker image and if the difference is more than 24 hours then we proceed to build
`get_image_build_time` - gets the last build date from `build_time` array
`check_adopt_image_available` - Checks if adopt image is available, if its not we proceed to build
`check_new_os_image_available` - We build the images if there is a change in base OS image, We inspect the image and check if the RoofFS layers checksum matches if not we proceed to build the image

- So now if the build is needed we proceed to docker build, If for some reason the build fails we call `cleanup_images` and `cleanup_manifest` to remove the image and manifests


