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
# ------------------------------------------------------------------------------
import requests
import json
import copy
import argparse
import logging
from logging import config
from datetime import datetime, timedelta
from pathlib import Path


LOGGER = logging.getLogger(__name__)


def load_logging_config(debug, file_path):
    """
    Loads and configures a logging config
    :param debug: True or False if debugging for console should be turned on
    :param file_path: File path to storage the log file
    :return: None
    """
    logging_config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "debugFormater": {
                "format": "%(asctime)s.%(msecs)03d %(levelname)s:%(message)s",
                "datefmt": "%Y-%m-%d %H:%M:%S"
            },
            "simpleFormater": {
                "format": "%(message)s"
            }
        },
        "handlers": {
                "file": {
                    "class": "logging.FileHandler",
                    "formatter": "debugFormater",
                    "level": "DEBUG",
                    "filename": "adoptopenjdk_scanner.log"
                },
                "console": {
                    "class": "logging.StreamHandler",
                    "formatter": "simpleFormater",
                    "level": "INFO",
                    "stream": "ext://sys.stdout"
                }
        },
        "loggers": {
            "": {
                "level": "DEBUG",
                "handlers": ["file"]
            },
            "__main__": {
                "level": "DEBUG",
                "handlers": ["console"],
                "propagate": True
            }
        }
    }

    # If debugging, then switch the console format to be verbose
    if debug:
        logging_config["handlers"]["console"]["formatter"] = "debugFormater"

    # If a file path is passed in then hadnle the prefix and append the file name
    if file_path:
        log_path = Path(file_path)
        log_path = log_path.joinpath(logging_config["handlers"]["file"]["filename"])
        logging_config["handlers"]["file"]["filename"] = str(log_path)

    # Apply logging config
    logging.config.dictConfig(logging_config)
    LOGGER.debug("Logging Config: " + str(logging_config))
    LOGGER.debug("Logging is configured")


def sanitize_build(build):
    """
    Takes a build name and processes it for tagging
    :param build: String - Name of build - (full/slim)
    :return: String - Name of processed build - (""/-slim)
    """
    if build == "full":
        return ""
    elif build == "slim":
        return "-" + build


def sanitize_jvm(jvm):
    """
    Takes a JVM name and processes it for tagging
    :param jvm: String - Name of JVM - (hotspot/openj9)
    :return: String - Name of processed JVM - (""/-openj9)
    """
    if jvm == "hotspot":
        return ""
    elif jvm == "openj9":
        return "-" + jvm


def docker_arch_names(arch):
    """
    Convert architecture names to a friendly name
    :param arch: String of the arch
    :return: String of the "friendly" arch name
    """
    if arch == "armv7l":
        return "arm"
    elif arch == "aarch64":
        return "arm64"
    elif arch == "x86_64":
        return "amd64"
    elif arch == "ppc64le":
        return "ppc64le"
    elif arch == "s390x":
        return "s390x"
    else:
        LOGGER.error("{arch} is an unsupport architecture!".format(arch=arch))
        raise ValueError("{arch} is an unsupport architecture!".format(arch=arch))


def convert_timedelta(duration):
    """
    Takes in Timedelta and converts it to days, hours, minutes and seconds
    :param duration: Timedelta Timestamp
    :return: Days, Hours, Minutes and Seconds
    """
    days, seconds = duration.days, duration.seconds
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    seconds = (seconds % 60)

    # Make sure if negative numbers are rounded up to 0
    days = max(0, days)
    hours = max(0, hours)
    minutes = max(0, minutes)
    seconds = max(0, seconds)

    return days, hours, minutes, seconds


def enrich_list_with_image_json(image_list, docker_org="adoptopenjdk"):
    """
    Enriches an image list with the image json data from docker api
    :param image_list: List of images
    :param docker_org: Name of the docker organization
    :return: Enriched image list
    """
    # Get a list that has only one copy each possible image to save on image checks
    manifest_list = get_manifest_list(image_list=image_list)

    # Enrich the manifest list with image json
    for image in manifest_list:
        image_json = get_image_information(docker_org=docker_org, docker_repo="openjdk{version}{jvm}".format(version=image["version"], jvm=sanitize_jvm(image["jvm"])), tag_name=image["tag"])
        image["image_json"] = image_json

    # Enrich the full image list with image json to avoid calling the same manifest 4 or 5 times(for each arch)
    for image in image_list:
        for enrich_image in manifest_list:
            if image["tag"] == enrich_image["tag"] and image["jvm"] == enrich_image["jvm"]:
                image["image_json"] = enrich_image["image_json"]

    return image_list


def deenrich_list_with_image_json(enriched_image_list):
    """
    De-enrich the image list
    :param enriched_image_list: List of enriched images
    :return: De-enriched image list
    """

    # For each image delete image json
    for image in enriched_image_list:
        if "image_json" in image:
            del image["image_json"]

    return enriched_image_list


def get_image_information(docker_org, docker_repo, tag_name):
    """
    Fetch image json from DockerHub for an image
    :param docker_org: Name of docker organization
    :param docker_repo: Name of docker repo
    :param tag_name: Name of tag
    :return: JSON of the image
    """
    LOGGER.debug("Getting image information for: {org}/{repo}:{tag}".format(org=docker_org, repo=docker_repo, tag=tag_name))
    response = requests.get("https://hub.docker.com/v2/repositories/{org}/{repo}/tags/{tag}".format(org=docker_org, repo=docker_repo, tag=tag_name))

    # Checks if the response is not a 5XX or 4XX status code
    if response.ok:
        return response.json()
    else:
        # If "bad" status code print error
        LOGGER.error("ERROR: Something went wrong grabbing image, {org}/{repo}:{tag}. HTTP Status Code: {code}".format(org=docker_org, repo=docker_repo, tag=tag_name, code=response.status_code))
        return None


def get_last_updated_for_image(image_json):
    """
    Grab "last_updated" timestamp from docker image json
    :param image_json: Image JSON
    :return: Datetime Object
    """
    # Grab the timestamp for last time updated
    last_updated = image_json.get("last_updated")

    # If last_update is not empty
    if last_updated is not None:
        # Parse timestamp string to datetime object
        timestamp = datetime.strptime(last_updated, "%Y-%m-%dT%H:%M:%S.%fZ")

        return timestamp
    else:
        # This should not happen unless Docker API changes the format/response
        LOGGER.error("last_updated value in the image json is not there. Has the DockerHub API changed?")
        raise ValueError("last_updated value in the image json is not there. Has the DockerHub API changed?")


def get_manifest_list(image_list):
    """
    Get a list with only the "manifest" images
    :param image_list: Full image list
    :return: "Unique" image list
    """
    # Create a copy of the image list
    manifest_list = copy.deepcopy(image_list)

    # Delete arch from image dicts, thus produce a list with duplicate values
    for image in manifest_list:
        del image["arch"]

    # Get unique list for manifest checking. Normal images list contain an entry for each arch thus "duplicates"
    # Converts dict to tuple to be able to generate hash for comparision
    manifest_list = [dict(t) for t in {tuple(d.items()) for d in manifest_list}]

    return manifest_list


def get_unique_image_name_and_last_updated(enriched_image_list):
    """
    Generate a list with "manifest" images only and last_update timestamp
    :param enriched_image_list: Image list with image JSON
    :return: List of tuples(image name and timestamp)
    """
    # Use a set to avoid adding the same image twice
    unique_list = set()

    for image in enriched_image_list:
        image_name = "adoptopenjdk/openjdk{version}{jvm}:{tag}".format(version=image["version"],
                                                                       jvm=sanitize_jvm(image["jvm"]), tag=image["tag"])
        last_updated = get_last_updated_for_image(image_json=image["image_json"])

        # Need to use tuples not dicts to take advantage of a set
        unique_list.add((image_name, last_updated))

    return list(unique_list)


def generate_all_image(supported_versions, supported_jvms, supported_os, supported_packages, supported_builds, supported_archs, dict_image_template):
    """
    Generates all possible combinations of images. Should take in any parameters that make up your image/tag
    :param supported_versions: String - List of Versions
    :param supported_jvms: String - List of JVMs
    :param supported_os: String - List of OSs
    :param supported_packages: String - List of Packages
    :param supported_builds: String - List of Builds
    :param supported_archs: String - List of Architectures
    :param dict_template: Dict - Template Dict to store needed information about said image/tag
    :return: List - All generate image/tag possibilities
    """
    # A list to hold all the possible images
    master_list = []

    # Loop over every possible image and check if it needs to be tested
    for version in supported_versions:
        for jvm in supported_jvms:
            for os in supported_os:
                for package in supported_packages:
                    for build in supported_builds:
                        for arch in supported_archs:
                            # Using Deep copy to make a new dict not just over writing the same one
                            template = copy.deepcopy(dict_image_template)
                            template["version"] = version
                            template["jvm"] = jvm
                            template["arch"] = arch
                            template["os"] = os
                            template["package"] = package
                            template["build"] = build
                            template["tag"] = "{package}{version}u-{os}-nightly{build}".format(package=package,
                                                                                               version=version, os=os,
                                                                                               build=sanitize_build(
                                                                                                   build))
                            master_list.append(template)

    return master_list


def is_valid_package_and_build(package, build):
    """
    Returns true or false depending on the package and build are jre and slim
    :param package: String - Package name - (jdk/jre)
    :param build: String - Build name - (slim/full)
    :return: Boolean - (True/False)
    """
    # Currently we do not produce JRE SLIM builds
    if package == "jre" and build == "slim":
        LOGGER.debug("Package & Build Check Failed with {package} and {build}".format(package=package, build=build))
        return False

    return True


def filter_valid_package_and_build(image_list):
    """
    Filter out any non-valid image by package and build
    :param image_list: List - Collection of possible images/tags
    :return: Tuple - First list is valid images and second list is non-valid images
    """
    filtered_list = []
    removed_list = []

    # Loop over all the images
    for image in image_list:
        # If valid added it to filter list
        if is_valid_package_and_build(package=image["package"], build=image["build"]):
            filtered_list.append(image)
        # If non-valid add it to the "removed" list
        else:
            removed_list.append(image)

    return (filtered_list, removed_list)


def is_valid_os_and_arch(os, arch):
    """
    Returns true or false depending on arch and os combination
    :param os: String - Name of OS - See supported OSs
    :param arch: String - Name of Arch - See supported Archs
    :return: Boolean - (True/False)
    """
    # ClefOS only runs on s390x
    if os == "clefos" and arch != "s390x":
        LOGGER.debug("OS Check Failed with {os} and {arch}".format(os=os, arch=arch))
        return False
    # CentOS does not support s390x
    elif os == "centos" and arch == "s390x":
        LOGGER.debug("OS Check Failed with {os} and {arch}".format(os=os, arch=arch))
        return False
    # Ubi based images do not support armv7l
    elif os == "ubi" and arch == "armv7l":
        LOGGER.debug("OS Check Failed with {os} and {arch}".format(os=os, arch=arch))
        return False
    # Ubi-minimal based images do not support armv7l
    elif os == "ubi-minimal" and arch == "armv7l":
        LOGGER.debug("OS Check Failed with {os} and {arch}".format(os=os, arch=arch))
        return False

    return True


def filter_valid_os_and_arch(image_list):
    """
    Filter out any non-valid image by package and build
    :param image_list: List - Collection of possible images/tags
    :return: Tuple - First list is valid images and second list is non-valid images
    """
    filtered_list = []
    removed_list = []

    # Loop over all the images
    for image in image_list:
        # If valid added it to filter list
        if is_valid_os_and_arch(os=image["os"], arch=image["arch"]):
            filtered_list.append(image)
        # If non-valid add it to the "removed" list
        else:
            removed_list.append(image)

    return (filtered_list, removed_list)


def is_valid_jvm_and_arch(jvm, arch):
    """
    Check if the jvm and arch are a valid combination
    :param jvm: Name of JVM
    :param arch: Name of arch
    :return: Boolean
    """
    # Currently OpenJ9 does not support armv7l or aarch64
    # But Hotspot supports all supported_archs
    if jvm == "openj9" and (arch == "armv7l" or arch == "aarch64"):
        LOGGER.debug("JVM Check Failed with {jvm} and {arch}".format(jvm=jvm, arch=arch))
        return False

    return True


def filter_valid_jvm_and_arch(image_list):
    """
    Filter list based on jvm and arch
    :param image_list: List of images
    :return: Dict of filtered and removed images
    """
    filtered_list = []
    removed_list = []

    # Loop over all the images
    for image in image_list:
        # If valid added it to filter list
        if is_valid_jvm_and_arch(jvm=image["jvm"], arch=image["arch"]):
            filtered_list.append(image)
        # If non-valid add it to the "removed" list
        else:
            removed_list.append(image)

    return (filtered_list, removed_list)


def is_image_exist(docker_org, docker_repo, tag_name):
    """
    Checks if image exists on DockerHub
    :param docker_org: Name of docker organization
    :param docker_repo: Name of docker repo
    :param tag_name: Name of tag
    :return: Boolean
    """
    # Issue GET request to get a HTTP Status code to check if it is a valid image
    # Using GET instead of HEAD because HEAD is not being treated right, thus enable stream to just get headers
    response = requests.get("https://hub.docker.com/v2/repositories/{org}/{repo}/tags/{tag}".format(org=docker_org, repo=docker_repo, tag=tag_name),  stream=True)

    LOGGER.debug("HTTP Status Code: {code}".format(code=response.status_code))
    # Checks if the response is not a 5XX or 4XX status code
    if response.ok:
        return True
    elif response.status_code == 404:
        LOGGER.debug("ERROR: Image, {org}/{repo}:{tag}, does not exist!".format(org=docker_org, repo=docker_repo, tag=tag_name))
        return False
    else:
        # Should never get another type of status code from Dockerhub then 200 or 404
        LOGGER.error("ERROR: When requesting the image, {org}/{repo}:{tag}, we got the HTTP status code, {code}. Network issues?".format(org=docker_org, repo=docker_repo, tag=tag_name, code=response.status_code))
        raise ValueError("ERROR: When requesting the image, {org}/{repo}:{tag}, we got the HTTP status code, {code}. Network issues?".format(org=docker_org, repo=docker_repo, tag=tag_name, code=response.status_code))


def filter_image_exist(docker_org, image_list):
    """
    Filter images based on if they exist or not
    :param docker_org: Name of docker organization
    :param image_list: List of images
    :return: Dict of filtered and removed images
    """
    filtered_list = []
    removed_list = []

    # Get a list that has only one copy each possible image to save on image checks
    manifest_list = get_manifest_list(image_list=image_list)

    removed_manifest_list = []

    # Loop over all possible images
    for image in manifest_list:
        if is_image_exist(docker_org=docker_org, docker_repo="openjdk{version}{jvm}".format(version=image["version"], jvm=sanitize_jvm(image["jvm"])), tag_name=image["tag"]) is not True:
            removed_manifest_list.append(image["tag"])

    # Filter the image list based on if the image did not exist
    for image in image_list:
        # Add image to the removed list if in removed_manifest_list
        if image["tag"] in removed_manifest_list:
            removed_list.append(image)
        else:
            filtered_list.append(image)

    return (filtered_list, removed_list)


def is_arch_in_manifest(arch, image_json):
    """
    Check if the architecture is in the manifest/image json
    :param arch: Name of architecture
    :param image_json: JSON of image
    :return: Boolean
    """
    # Grab the images value the image json. Should be a list if its a manifest
    manifest_images = image_json.get("images")

    if manifest_images is not None:
        for image in manifest_images:
            if docker_arch_names(arch=arch) == image.get("architecture"):
                return True

        return False
    else:
        LOGGER.error("images value in the image json is not there. Has the DockerHub API changed?")
        raise ValueError("images value in the image json is not there. Has the DockerHub API changed?")


def filter_arch_in_manifest(enriched_image_list, filter_images=True):
    """
    Filter image list based on if the architecture is in the manifest/image json
    :param enriched_image_list: List of images with image JSON
    :param filter_images: If set to False, images that are not in the manifest will remain in the list
    :return: Dict of filtered and removed images
    """
    filtered_list = []
    removed_list = []

    for image in enriched_image_list:
        if is_arch_in_manifest(arch=image["arch"], image_json=image["image_json"]):
            filtered_list.append(image)
        else:
            removed_list.append(image)

    # If filter_images is false, we want to keep the "bad" images in the list
    if filter_images is False:
        filtered_list = copy.deepcopy(enriched_image_list)

    return (filtered_list, removed_list)


def is_timedelta(timestamp, current_time=datetime.utcnow(), delta_hours=2):
    """
    Check if the given timestamp is within a time delta
    :param timestamp: Timestamp of image(UTC)
    :param current_time: Current UTC timestamp
    :param delta_hours: An integer of hours
    :return: Boolean
    """
    # Check the timestamps are within a given delta
    # Checking if the given timestamp + delta hours is great then the current time aka making it a "new" image
    # If less then current time the image is deemed "old"
    if (timestamp + timedelta(hours=delta_hours)) > current_time:
        return True
    else:
        return False


def filter_timedelta(enriched_image_list, delta_hours=2):
    """
    Filter images based on time delta
    :param enriched_image_list: List of images with image JSON
    :param delta_hours: An integer of hours
    :return: Dict of filtered and removed images
    """
    filtered_list = []
    removed_list = []

    for image in enriched_image_list:
        if is_timedelta(timestamp=get_last_updated_for_image(image_json=image["image_json"]), current_time=datetime.utcnow(), delta_hours=delta_hours):
            filtered_list.append(image)
        else:
            removed_list.append(image)

    return (filtered_list, removed_list)


def general_filters(image_list, dict_images_template):
    """
    Filters out images that should not be valid exist
    :param image_list: List of images
    :param dict_images_template: Images template
    :return: Dict of images
    """
    # Filter by package and build
    image_list, dict_images_template["package_and_build"] = filter_valid_package_and_build(image_list)

    # Filter by os and arch
    image_list, dict_images_template["os_and_arch"] = filter_valid_os_and_arch(image_list)

    # Filter by jvm and arch
    image_list, dict_images_template["jvm_and_arch"] = filter_valid_jvm_and_arch(image_list)

    # Remaining images must be valid after going through the above filters
    dict_images_template["filtered_images"] = image_list

    return dict_images_template


def verify_images(image_list, dict_images_template, docker_org="adoptopenjdk"):
    """
    Verify a list of images exists
    :param image_list: List of images
    :param dict_images_template: Images template
    :param docker_org: Name of docker organization
    :return: Dict of images
    """
    # Apply general filter for the image list. This makes sure all images are valid
    dict_images_template = general_filters(image_list, dict_images_template)

    # Check if the images exist by using the filter
    dict_images_template["filtered_images"], dict_images_template["bad_requests"] = filter_image_exist(docker_org=docker_org, image_list=dict_images_template["filtered_images"])

    return dict_images_template


def verify_manifests(image_list, dict_images_template, docker_org="adoptopenjdk", filter_bad_manifests=True):
    """
    Verify a list of images have valid manifests
    :param image_list: List of images
    :param dict_images_template: Images template
    :param docker_org: Name of docker organization
    :param filter_bad_manifests: Filter out bad manifests from list if set to true
    :return: Dict of images
    """
    # Call verify images to make sure they all exist before further processing
    dict_images_template = verify_images(image_list=image_list, dict_images_template=dict_images_template, docker_org=docker_org)

    # Enrich the images with image JSON
    enriched_image_list = enrich_list_with_image_json(image_list=dict_images_template["filtered_images"], docker_org=docker_org)

    # Check if the manifests are "bad" by using the filter
    dict_images_template["filtered_images"], dict_images_template["bad_manifests"] = filter_arch_in_manifest(enriched_image_list=enriched_image_list,  filter_images=filter_bad_manifests)

    # De-enrich the images before storing them into the dict
    dict_images_template["bad_manifests"] = deenrich_list_with_image_json(enriched_image_list=dict_images_template["bad_manifests"])

    return dict_images_template


def verify_timedelta(image_list, dict_images_template, docker_org="adoptopenjdk", filter_bad_manifests=True, delta_hours=2, force_old_images=False):
    """
    Verify a list of images meet a given time delta
    :param image_list: List of images
    :param dict_images_template: Images template
    :param docker_org: Name of docker organization
    :param filter_bad_manifests: Filter out bad manifests from list if set to true
    :param delta_hours: An integer of hours to deem an image "old"
    :param force_old_images: Forces old images to not be filtered out
    :return: Dict of images
    """
    # Call verify manifests to make use all manifests are okay. Calling manifest also verifies if the images exist too
    dict_images_template = verify_manifests(image_list=image_list, dict_images_template=dict_images_template, docker_org=docker_org, filter_bad_manifests=filter_bad_manifests)

    # Force Old Images set to true will skip the delta time check
    if force_old_images is not True:
        dict_images_template["filtered_images"], dict_images_template["old_images"] = filter_timedelta(enriched_image_list=dict_images_template["filtered_images"], delta_hours=delta_hours)

    return dict_images_template


def verify(image_list, dict_images_template, docker_org="adoptopenjdk", filter_bad_manifests=False, delta_hours=2, force_old_images=False):
    """
    Verify a list of images meet all filters. Used to generate a list of images that need to be tested
    :param image_list: List of images
    :param dict_images_template: Images template
    :param docker_org: Name of docker organization
    :param filter_bad_manifests: Filter out bad manifests from list if set to true
    :param delta_hours: An integer of hours to deem an image "old"
    :param force_old_images: Forces old images to not be filtered out
    :return: Dict of images
    """
    # Call verify time delta to make sure all images are not "old". This calls verifies manifests and if the images exist
    dict_images_template = verify_timedelta(image_list=image_list, dict_images_template=dict_images_template, docker_org=docker_org, filter_bad_manifests=filter_bad_manifests, delta_hours=delta_hours, force_old_images=force_old_images)

    # De-enrich images before storing them in image dict
    dict_images_template["filtered_images"] = deenrich_list_with_image_json(enriched_image_list=dict_images_template["filtered_images"])

    return dict_images_template


def output_package_and_build(image_dict, json_output):
    """
    Outputs a list of images that failed the package and build filter
    :param image_dict: Dictionary of images
    :param json_output: Boolean for Json output verse printed
    :return: None
    """
    LOGGER.info("\nPackage and Build Image Issues({number}):".format(number=str(len(image_dict["package_and_build"]))))
    for image in image_dict["package_and_build"]:
        if json_output is False:
            image_name = "adoptopenjdk/openjdk{version}{jvm}:{tag}".format(version=image["version"], jvm=sanitize_jvm(image["jvm"]), tag=image["tag"])
            LOGGER.info("Package & Build Check Failed with {package} and {build} for image: {image_name}".format(package=image["package"], build=image["build"], image_name=image_name))
        else:
            LOGGER.info(json.dumps(image))


def output_os_and_arch(image_dict, json_output):
    """
    Outputs a list of images that failed the os and arch filter
    :param image_dict: Dictionary of images
    :param json_output: Boolean for Json output verse printed
    :return: None
    """
    LOGGER.info("\nOS and Image Image Issues({number}):".format(number=str(len(image_dict["os_and_arch"]))))
    for image in image_dict["os_and_arch"]:
        if json_output is False:
            image_name = "adoptopenjdk/openjdk{version}{jvm}:{tag}".format(version=image["version"], jvm=sanitize_jvm(image["jvm"]), tag=image["tag"])
            LOGGER.info("OS Check Failed with {os} and {arch} for image: {image_name}".format(os=image["os"], arch=image["arch"], image_name=image_name))
        else:
            LOGGER.info(json.dumps(image))


def output_jvm_and_arch(image_dict, json_output):
    """
    Outputs a list of images that failed the jvm and arch filter
    :param image_dict: Dictionary of images
    :param json_output: Boolean for Json output verse printed
    :return: None
    """
    LOGGER.info("\nJVM and Architecture Image Issues({number}):".format(number=str(len(image_dict["jvm_and_arch"]))))
    for image in image_dict["jvm_and_arch"]:
        if json_output is False:
            image_name = "adoptopenjdk/openjdk{version}{jvm}:{tag}".format(version=image["version"], jvm=sanitize_jvm(image["jvm"]), tag=image["tag"])
            LOGGER.info("JVM Check Failed with {jvm} and {arch} for image: {image_name}".format(jvm=image["jvm"], arch=image["arch"], image_name=image_name))
        else:
            LOGGER.info(json.dumps(image))


def output_bad_requests(image_dict, json_output, valid_images):
    """
    Outputs a list of images that do not exist in DockerHub/generated a bad request. Also can out print "valid" images
    :param image_dict: Dictionary of images
    :param json_output: Boolean for Json output verse printed
    :param valid_images: Boolean for if Valid images should be shown
    :return: None
    """
    manifest_list = get_manifest_list(image_list=image_dict["bad_requests"])

    LOGGER.info("\nNonexistent(Bad Requests) Image Issues({number}):".format(number=str(len(manifest_list))))
    for image in manifest_list:
        if json_output is False:
            image_name = "adoptopenjdk/openjdk{version}{jvm}:{tag}".format(version=image["version"], jvm=sanitize_jvm(image["jvm"]), tag=image["tag"])
            LOGGER.info("Got a bad request for image: {image_name}".format(image_name=image_name))
        else:
            LOGGER.info(json.dumps(image))

    if valid_images is True:
        valid_manifest_list = get_manifest_list(image_list=image_dict["filtered_images"])
        LOGGER.info("\nExistent(Good Requests) Images({number}):".format(number=str(len(valid_manifest_list))))
        for image in valid_manifest_list:
            if json_output is False:
                image_name = "adoptopenjdk/openjdk{version}{jvm}:{tag}".format(version=image["version"], jvm=sanitize_jvm(image["jvm"]), tag=image["tag"])
                LOGGER.info("Got a good request for image: {image_name}".format(image_name=image_name))
            else:
                LOGGER.info(json.dumps(image))


def output_old_images(image_dict, json_output, valid_images, delta_hours):
    """
    Outputs a list of images that are deemed "old" by a given time delta. Also can out print "valid" images
    :param image_dict: Dictionary of images
    :param json_output: Boolean for Json output verse printed
    :param valid_images: Boolean for if Valid images should be shown
    :param delta_hours: An integer of hours to deem an image "old"
    :return: None
    """
    if json_output is False:
        image_name_and_last_updated = get_unique_image_name_and_last_updated(enriched_image_list=image_dict["old_images"])

        LOGGER.info("\nDelta Time(Old) Image Issues({number}):".format(number=str(len(image_name_and_last_updated))))
        for image_name, timestamp in image_name_and_last_updated:
                age_of_image = datetime.utcnow() - timestamp
                days, hours, minutes, seconds = convert_timedelta(age_of_image)
                LOGGER.info("Failed delta time check of {delta_hours} hours with the age of {days} days, {hours:02d}:{minutes:02d}.{seconds:02d} for image: {image_name}".format(delta_hours=delta_hours, days=days, hours=hours, minutes=minutes, seconds=seconds, image_name=image_name))

        if valid_images is True:
            image_name_and_last_updated = get_unique_image_name_and_last_updated(enriched_image_list=image_dict["filtered_images"])

            LOGGER.info("\nDelta Time(NEW) Images({number}):".format(number=str(len(image_name_and_last_updated))))
            for image_name, timestamp in image_name_and_last_updated:
                age_of_image = timestamp - datetime.utcnow()
                days, hours, minutes, seconds = convert_timedelta(age_of_image)
                LOGGER.info("Passed delta time check of {delta_hours} hours with the age of {days} days, {hours:02d}:{minutes:02d}.{seconds:02d}  for image: {image_name}".format(delta_hours=delta_hours, days=days, hours=hours, minutes=minutes, seconds=seconds, image_name=image_name))
    else:
        LOGGER.info("\nDelta Time(Old) RAW Image Issues({number}):".format(number=str(len(image_dict["old_images"]))))
        for image in image_dict["old_images"]:
            LOGGER.info(json.dumps(image))

        if valid_images is True:
            LOGGER.info("\nDelta Time(NEW) RAW Images({number}):".format(number=str(len(image_dict["filtered_images"]))))
            for image in image_dict["filtered_images"]:
                LOGGER.info(json.dumps(image))


def output_bad_manifests(image_dict, json_output):
    """
    Outputs of a list of images that have manifest issues
    :param image_dict: Dictionary of images
    :param json_output: Boolean for Json output verse printed
    :return: None
    """

    if json_output is False:
        manifest_dict = {}

        for image in image_dict["bad_manifests"]:
            image_name = "adoptopenjdk/openjdk{version}{jvm}:{tag}".format(version=image["version"], jvm=sanitize_jvm(image["jvm"]), tag=image["tag"])
            if image_name in manifest_dict:
                manifest_dict[image_name] = manifest_dict[image_name] + ", " + image["arch"]
            else:
                manifest_dict[image_name] = image["arch"]

        LOGGER.info("\nManifest Image Issues({number}):".format(number=str(len(image_dict["bad_manifests"]))))
        for key, value in manifest_dict.items():
            LOGGER.info(key + " : " + value)
    else:
        LOGGER.info("\nManifest RAW Image Issues({number}):".format(number=str(len(image_dict["bad_manifests"]))))
        for image in image_dict["bad_manifests"]:
            LOGGER.info(json.dumps(image))


def output_filtered_images(image_dict, json_output):
    """
    Outputs a list of images that need to be tested
    :param image_dict: Dictionary of images
    :param json_output: Boolean for Json output verse printed
    :return: None
    """
    if json_output is False:
        manifest_list = get_manifest_list(image_list=image_dict["filtered_images"])
        LOGGER.info("Valid(Filtered) Images({number}):".format(number=str(len(manifest_list))))
        for image in manifest_list:
            image_name = "adoptopenjdk/openjdk{version}{jvm}:{tag}".format(version=image["version"], jvm=sanitize_jvm(image["jvm"]), tag=image["tag"])
            LOGGER.info("All attributes have been verified for image: {image_name}".format(image_name=image_name))
    else:
        LOGGER.info("Valid(Filtered) RAW Images({number}):".format(number=str(len(image_dict["filtered_images"]))))
        for image in image_dict["filtered_images"]:
            LOGGER.info(json.dumps(image))


def get_args():
    """
    Processes and handles command line arguments
    :return: Dict of command line arguments
    """
    parser = argparse.ArgumentParser(description="AdoptOpenJDK Scanner allows a user to verify attributes about images")
    parser.add_argument("--verify",
                        help="Name of the attribute you want to verify",
                        type=str,
                        choices=["all", "timedelta", "manifests", "images"],
                        default=None,
                        required=True)
    parser.add_argument("--versions",
                        help="Java Versions",
                        nargs='+',
                        type=str,
                        choices=["8", "11", "14"],
                        default=["8", "11", "14"])
    parser.add_argument("--jvms",
                        help="Name of the JVMs",
                        nargs='+',
                        type=str,
                        choices=["hotspot", "openj9"],
                        default=["hotspot", "openj9"])
    parser.add_argument("--oss",
                        help="Names of the OSs",
                        nargs='+',
                        type=str,
                        choices=["alpine", "debian", "debianslim", "ubi", "ubi-minimal", "centos", "clefos", "ubuntu", "alma", "alma-minimal" ],
                        default=["alpine", "debian", "debianslim", "ubi", "ubi-minimal", "centos", "clefos", "ubuntu", "alma", "alma-minimal" ])
    parser.add_argument("--packages",
                        help="Names of the Packages",
                        nargs='+',
                        type=str,
                        choices=["jdk", "jre"],
                        default=["jdk", "jre"])
    parser.add_argument("--archs",
                        help="Architectures",
                        nargs='+',
                        type=str,
                        choices=["armv7l", "aarch64", "ppc64le", "s390x", "x86_64"],
                        default=["armv7l", "aarch64", "ppc64le", "s390x", "x86_64"])
    parser.add_argument("--builds",
                        help="Name of the Builds",
                        nargs='+',
                        type=str,
                        choices=["slim", "full"],
                        default=["slim", "full"])
    parser.add_argument("--filter-bad-manifests",
                        help="Filter out bad manifest images",
                        action="store_true",
                        default=False)
    parser.add_argument("--delta-hours",
                        help="Number of hours to deem an image 'old'",
                        type=int,
                        default=2)
    parser.add_argument("--force-old-images",
                        help="Force old images not to be filtered out",
                        action="store_true",
                        default=False)
    parser.add_argument("--debug",
                        help="Enable Debug output",
                        action="store_true",
                        default=False)
    parser.add_argument("--log-path",
                        help="Path to where the log file will be generated",
                        type=str,
                        default=None)
    parser.add_argument("--json",
                        help="Prints JSON output for results instead of formatted strings",
                        action="store_true",
                        default=False)
    parser.add_argument("--show-valid",
                        help="Prints valid objects in addition to the problematic objects. Only works for certain verify values",
                        action="store_true",
                        default=False)

    return vars(parser.parse_args())


def run(parsed_args):
    """
    Main function that takes in arguments and processes them
    :param parsed_args: Dict of command line arguments
    :return: None
    """
    docker_organization = "adoptopenjdk"

    image_template = {
        "version": "",
        "jvm": "",
        "arch": "",
        "os": "",
        "package": "",
        "build": "",
        "tag": ""
    }

    images_template = {
        "filtered_images": [],
        "package_and_build": [],
        "os_and_arch": [],
        "jvm_and_arch": [],
        "bad_requests": [],
        "bad_manifests": [],
        "old_images": []
    }

    LOGGER.info("Generating All Possible Images.......")
    all_images = generate_all_image(supported_versions=parsed_args["versions"], supported_jvms=parsed_args["jvms"], supported_os=parsed_args["oss"], supported_packages=parsed_args["packages"], supported_builds=parsed_args["builds"], supported_archs=parsed_args["archs"], dict_image_template=image_template)

    LOGGER.info("Processing images.......")
    if parsed_args["verify"] == "all":
        processed_dict = verify(image_list=all_images, dict_images_template=images_template, docker_org=docker_organization, filter_bad_manifests=parsed_args["filter_bad_manifests"], delta_hours=parsed_args["delta_hours"], force_old_images=parsed_args["force_old_images"])
        if parsed_args["debug"]:
            output_package_and_build(image_dict=processed_dict, json_output=parsed_args["json"])
            output_os_and_arch(image_dict=processed_dict, json_output=parsed_args["json"])
            output_jvm_and_arch(image_dict=processed_dict, json_output=parsed_args["json"])
            output_bad_requests(image_dict=processed_dict, json_output=parsed_args["json"], valid_images=parsed_args["show_valid"])
            output_bad_manifests(image_dict=processed_dict, json_output=parsed_args["json"])
            output_old_images(image_dict=processed_dict, json_output=parsed_args["json"], valid_images=parsed_args["show_valid"], delta_hours=parsed_args["delta_hours"])

        output_filtered_images(image_dict=processed_dict, json_output=parsed_args["json"])
    elif parsed_args["verify"] == "timedelta":
        processed_dict = verify_timedelta(image_list=all_images, dict_images_template=images_template, docker_org=docker_organization, filter_bad_manifests=parsed_args["filter_bad_manifests"], delta_hours=parsed_args["delta_hours"], force_old_images=parsed_args["force_old_images"])
        output_old_images(image_dict=processed_dict, json_output=parsed_args["json"], valid_images=parsed_args["show_valid"], delta_hours=parsed_args["delta_hours"])
    elif parsed_args["verify"] == "manifests":
        processed_dict = verify_manifests(image_list=all_images, dict_images_template=images_template, docker_org=docker_organization, filter_bad_manifests=parsed_args["filter_bad_manifests"])
        output_bad_manifests(image_dict=processed_dict, json_output=parsed_args["json"])
    elif parsed_args["verify"] == "images":
        processed_dict = verify_images(image_list=all_images, dict_images_template=images_template, docker_org=docker_organization)
        output_bad_requests(image_dict=processed_dict, json_output=parsed_args["json"],  valid_images=parsed_args["show_valid"])


if __name__ == "__main__":
    # Parse the arguments passed in
    args = get_args()

    # Configure logging
    load_logging_config(args["debug"], args["log_path"])

    LOGGER.debug("Parsed arguments: " + str(args))
    run(parsed_args=args)
