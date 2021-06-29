# Manifest process

The `manifest` process can be triggered by running the `update_manifest_all.sh`. Which creates the manifest commands script to be run.

The number of docker manifests that are created are based on the combination of

`version` \
`vm type` (Hotspot, OpenJ9) \
`package` (JDK, JRE) \
`os` \
`build type` (Release, Nightly) \
`package type` (slim, full)

## Workflow

### Step - 1:

`update_manifest_all.sh` loops over the `version` , `vm type` and `package`, triggers `generate_manifest_script.sh`
to create the manifest file for the particular combination

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

- Now we generate the manifest for the specific version, vm type & package, by calling the `generate_manifest_script.sh` script and passing these values as arguments.

`./generate_manifest_script.sh "${ver}" "${vm}" "${package}"`


### Step - 2:

we create the manifest commands for each `os`, `build` (Release or Nightly) and `build type`  (Full or Slim) combination for the given `version`, `vm` and `package type`

- Firstly we check if the manifest tool is available (docker), by calling the `check_manifest_tool` function, Which checks the location of docker and also check if the docker version supports manifest feature.

- We set the list of operating systems we generate the manifest for

`oses="alma alma-minimal alpine centos clefos debian debianslim leap tumbleweed ubi ubi-minimal ubuntu"`

- We now check which jvms are available for the given version by calling the `generate_latest_sums.sh` script so if the respective shasums file is generated for the version and vm combination then we add that to the `available_jvms`

`./generate_latest_sums.sh "${version}"`

```
available_jvms=""
if [ "${vm}" == "hotspot" ] && [ -f hotspot_shasums_latest.sh ]; then
  # shellcheck disable=SC1091
	source ./hotspot_shasums_latest.sh
	available_jvms="hotspot"
fi
if [ "${vm}" == "openj9" ] && [ -f openj9_shasums_latest.sh ]; then
 # shellcheck disable=SC1091
	source ./openj9_shasums_latest.sh
	available_jvms="${available_jvms} openj9"
fi
```

- Now we create the `manifest_commands.sh` file to start writing manifest commands to it and make it executable

`man_file=${root_dir}/manifest_commands.sh`

```
echo "#!/usr/bin/env bash" > "${man_file}"
echo  >> "${man_file}"
chmod +x "${man_file}"
```

- Now we iterate over the supported `oses`, `builds` and `build types` and write the manifest commands to the manifest file for respective os, build and build type

#### loop 1:

We iterate over the available operating systems

`for os in ${oses}`

- Now we get the supported builds, build types by parsing the vm config file for respective inputs

```
    # Build = Release or Nightly
	builds=$(parse_vm_entry "${vm}" "${version}" "${package}" "${os}" "Build:")
	# Type = Full or Slim
	btypes=$(parse_vm_entry "${vm}" "${version}" "${package}" "${os}" "Type:")
```

#### loop 2:

We iterate over the `builds` we got from the earlier step

`for build in ${builds}`

- Now we create the repo and tag information by checking the declared arrays (Eg: `jre_openj9_8_releases_sums`) for the version tag info

Example of a sample array declared after calling `get_shasums` :

```
declare -A jre_openj9_8_releases_sums=(
	[version]="jdk8u282-b08_openj9-0.24.0"
	[version-linux_aarch64]="jdk8u282-b08_openj9-0.24.0"
	[linux_aarch64]="1ffc7ac14546ee5e16e0efd616073baaf1b80f55abf61257095f132ded9da1e5"
	[version-linux_ppc64le]="jdk8u282-b08_openj9-0.24.0"
	[linux_ppc64le]="8a120156119902e4e51162d72716f57c57b7eed88f3b46b8720d9bac22701459"
	[version-linux_s390x]="jdk8u282-b08_openj9-0.24.0"
	[linux_s390x]="6e54e038c92778731a1f40dcf567850f695544a80fb02ec429e0c93654361bba"
	[version-linux_x86_64]="jdk8u282-b08_openj9-0.24.0"
	[linux_x86_64]="4fad259c32eb23ec98925c8b2cf28aaacbdb55e034db74c31a7636e75b6af08d"
	[version-windows_windows-amd]="jdk8u282-b08_openj9-0.24.0"
	[windows_windows-amd]="cb1ba5f2d086ac3fb6a875ac7749837c1b0a7493d988d0b2360a0f2b392255c3"
	[version-windows_windows-nano]="jdk8u282-b08_openj9-0.24.0"
	[windows_windows-nano]="3f2213c25b059f890bd0e383d7a64db58fd3dbc9a083fc1536b1ddacd28b3188"
)
```

We now set the repo with the `source_repo`, `version` and `vm` information

```
        srepo=${source_repo}${version}
		if [ "${vm}" != "hotspot" ]; then
			srepo=${srepo}-${vm}
		fi
```

#### loop - 3:

We iterate over the `build types`

`for btype in ${btypes}`

- We now go ahead and build the tag list for the specific combination of `vm`, `package`, `os`, `build` and `build type`

- We now parse the `tags.config` file in `config/tags.config` by using `parse_tag_entry` function (available in `common_functions.sh`) for specific key of the above mentioned combination to get the raw tags list

`raw_tags=$(parse_tag_entry "${os}" "${package}" "${build}" "${btype}")`

- We now proceed to build the tags by calling `build_tags` (available in `common_functions.sh`) function and passing `vm` `version` `package` `rel` `os` `build` `raw_tags` as the parameters

`build_tags "${vm}" "${version}" "${package}" "${rel}" "${os}" "${build}" "${raw_tags}"`

- In `build_tags` we create a temporary file (and delete it in the function's end) to write the architecture based tags (`arch_tags`) and generic tags (`tag_aliases`) by iterating over the `raw_tags` and we now add the tags to the `arch_tags` global variable

- We now proceed and call the `print_tags` function to iterate over the `arch_tags` and add the annotate commands for each tag with information of `os` and `arch`

`print_tags "${srepo}"`

Loop over the `arch_tags`

```
for arch_tag in ${arch_tags}
```

- We now check if the docker image is available for specific tag with `check_image` function and if it fails we skip that tag

`ret=$(check_image "${trepo}":"${arch_tag}")`

- We now add available tags to `img_list` and pass it to `print_manifest_cmd` to write it to the manifest file.

`print_manifest_cmd "${trepo}" "${img_list}"`

- Now for each tag alias we write the manifest create command to the manifest file

`for talias in ${tag_aliases}`

```
echo "\"${manifest_tool}\" manifest create ${trepo}:${talias} ${img_list}" >> "${man_file}"
```

- Now for each image tag in the `img_list` we write the annotate command to the manifest file by calling `print_annotate_cmd`

`print_annotate_cmd "${trepo}":"${talias}" "${img}"`

- Finally we add the push command at the last to push the manifest to the hub.docker.com

`echo "\"${manifest_tool}\" manifest push ${trepo}:${talias}" >> "${man_file}"`

- Once all the combinations are completed we run the `manifest_commands.sh` to execute the commands written to it and remove the temporary files

```
            cat manifest_commands.sh
			./manifest_commands.sh

			# Remove any temporary files
			rm -f hotspot_*_latest.sh openj9_*_latest.sh manifest_commands.sh
```


