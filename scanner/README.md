# AdoptOpenJDK Scanner
A Python based tool to scan and identify problematic Docker images published to DockerHub. 


## Install
There are two supported install methods, System Python or Docker Image.

### System Python
The tool only utilizes one third party Python module, `requests`. To install the need module you can issue the following
command:

```commandline
pip install -r requirements.txt
```

Please note this tool utilizes Python 3 to make sure you are using the appropriate `pip`. 

### Docker Image
To install and utilize the tool you can take advantage of a Docker image. You will need to build the Docker image and 
then run the image when you want to utilize the tool. This install method is helpful when you are concerned with 
cluttering up your system environment or need to run the tool on a remote system. 

To build the Docker image run the following command:

```commandline
docker build -t adoptopenjdk:scanner -f Dockerfile .
```

This will build the Docker image and tag it as `adoptopenjdk:scanner`. Feel free to tag the image with whatever name you
want.

After building the Docker image you can run and utilize the tool by issuing this command:

```commandline
docker run adoptopenjdk:scanner
```

Please note if you care about the log file that is generated you will need to mount a Docker volume or some kind of 
persistent storage. 


## Utilizing the Scanner
After you have the tool install you can start using it. The tool has a couple different commandline parameters that allow
you to fine tune your output.

### Help
`--help` or `-h` will produce additionally information on all the commandline parameters. All of the paremeters are 
outlined below in further detail.

### Verify
`--verify` allows you to select what kind of verification you want. The verification options are as follows:
- `images` allows you to verify if all the images exist in DockerHub. 
- `manifests` will identify any issues with the published manifests in DockerHub. 
- `tiemdelta` allows you to confirm that all images have been updated in X amount of hours.
- `all` will verify all the above tests and produce a list of images that "need" to be tested. 


### Image Options
When scanning for any issues with images published to DockerHub, you might want to only scan for a small subset of images.
There are a couple of image options to limit your set of images that you will be scanning. The image options are as follows:

- `--versions` - Sets the Java versions. The default is all of the active(LTS and current) Java versions. At this time they would be `8`, `11` and `14`.
- `--jvms` - Sets the JVMs. The default are both `openj9` and `hotspot`
- `--oss` - Sets the OSs. The defaults are `alpine`, `debian`, `debianslim`, `ubi`, `ubi-minimal`, `centos`, `clefos`, and `ubuntu`.
- `--packages` - Sets the packages. The defaults are both `jdk` and `jre`.
- `--archs` - Sets the architectures. The default are all the architectures AdoptOpenJDK builds for. That this time they would be `armv7l`, `aarch64`, `ppc64le`, `s390x`, and `x86_64`.
- `--builds` - Sets the builds. The default are both `slim` and `full`.

Please to run the tool none of these images options are required. If not passed in they will use the defaults stated above.
This will be how most users will utilize the tool. 


### Delta Hours
`--detla-hours` allows you to set the number of hours to deem an image "old". This means if an image has not been updated
in the last X hours, the image will be deemed "old". The default for this parameter is `2`. 

### Filter Bad Manifests
`--filter-bad-manifests` allows you to choice if images with manifest problems should be filtered out of the final list of images. 
This parameter should be used in conjunction with `--verify all` as it will affect the output. The default for this parameter is `False`.

Please note this is a flag parameter thus you do not need to pass in `False` or `True`. Just pass the flag as a commandline parameter. 


### Force Old Images
`--force-old-images` allows you to ignore the delta hours thus not deeming any image "old". This parameter is helpful
when you want to produce a full list of images to test. The default for this parameter is `False`. 

Please note this is a flag parameter thus you do not need to pass in `False` or `True`. Just pass the flag as a commandline parameter. 

### Debug
`--debug` allows you to see verbose output in the console. Pass in this flag when you are troubleshooting/debugging.

Please note this is a flag parameter thus you do not need to pass in `False` or `True`. Just pass the flag as a commandline parameter. 

### Log Path
`--log-path` allows you to specify the directory where you want the log file to be generated. By default the directory the
tool is in is where the log file will be generated. 

Please note you are just passing in the directory not the file name of the log. The file name of the log is `adoptopenjdk_scanner.log`.