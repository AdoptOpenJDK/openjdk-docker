# Docker Image Release Process

The docker image release process for quarterly releases and a new major release are slightly different.

## Quarterly Releases

* Create a issue to track the progress of the docker release images using the [release template](https://github.com/AdoptOpenJDK/openjdk-docker/issues/new?assignees=&labels=Release&template=docker-image-release-status-for-jdk-xyz.md&title=) issue.

* Check if the binaries of all arches are available
  * HotSpot (x86_64, ppc64le, s390x, arm32, aarch64)
    - It is common for hotspot arm32 and aarch64 builds to be delayed. 
	- The usual criteria is if the arm related builds are going to be available within a couple of days of the other builds, then we wait for the builds to become available before raising the PR at the official repo. If it is expected to take longer than 2 days, we push the remaining arches right away, alerting the official maintainers of possible breakage downstream.
  * OpenJ9  (x86_64, ppc64le, s390x)

#### Official Images

Official images are maintained by the Docker community and updates are done through the official [github repo](https://github.com/docker-library/official-images). This requires an update to the Dockerfiles in this repo and a subsequent PR at the official repo with the commit id that has all the Dockerfile updates.

  * Generate the updated dockerfiles
    - [./update_all.sh](update_all.sh)

  * If there are arches for which builds are missing you should see warnings such as this
    ```
    Parent version not matching for arch aarch64: jdk8u275-b01, jdk8u282-b08
    Parent version not matching for arch armv7l: jdk8u275-b01, jdk8u282-b08
    ```

    In the above example, This means that for aarch64 and armv7l, builds of the latest version (jdk8u282-b08) are not yet available.

  * Raise a PR for the updated Dockerfiles in this repo. See this [PR](https://github.com/AdoptOpenJDK/openjdk-docker/pull/502) for example.

  * Once the PR is merged, generate the updated files for raising the [PR at the official repo](https://github.com/docker-library/official-images/pull/9853).
    * [./dockerhub_doc_config_update.sh](dockerhub_doc_config_update.sh)
  * The file `adoptopenjdk` can be mostly copied over to [library/adoptopenjdk](https://github.com/docker-library/official-images/blob/master/library/adoptopenjdk) at the official repo. However,
    - OS tags may need to be updated if there are OS version changes (This is not automated)
    - Ensure we are not removing any arches / OSes that are currently active and only the versions are changing / added.
  * PRs pending related to this at the Adopt repo.
    - Add script to update dockerfiles on a [PR merge](https://github.com/AdoptOpenJDK/openjdk-docker/pull/466).

#### Non-Official Images

Non-official images are maintained by the AdoptOpenJDK community primarily through this repo. The images are automatically updated by the [nightly builds](https://ci.adoptopenjdk.net/view/Docker%20Images/job/openjdk_build_docker_multiarch/) for the quarterly releases.

  * Ideally it is best to stop automated nightly builds (which also build release images) from running during the duration of the release. This is needed as the release tarballs for different arches trickle in and cause inconsistencies in the manifest entries.
  * Manually trigger the nightly build once the required arch builds for a release are available.
  * Re-enable automated nightly builds once all the release builds are pushed to DockerHub from the previous step.
  * In the official image section, after we run [dockerhub_doc_config_update.sh](dockerhub_doc_config_update.sh), it produces text files for each supported release that consists of all the valid tags. This can be copy-pasted as-is to the corresponding dockerhub repo [readme](https://hub.docker.com/repository/docker/adoptopenjdk/openjdk16/general).

## Major Releases

For a new major release, there are some additional steps to be done prior to the quarterly release steps that are documented above.

#### Script Changes

There are some script changes to be done to enable building a new major release. See this [PR](https://github.com/AdoptOpenJDK/openjdk-docker/pull/527/files) for example. 
* [continuous-integration-workflow.yml](.github/workflows/continuous-integration-workflow.yml)
  * Add the new version to be built. (You may need to deprecate an older version as we only maintain docker image builds for the last two major releases (not counting LTS releases).
* [common_functions.sh](common_functions.sh)
  *  Update `supported_versions` and function `check_version` to add the new version. Change `latest_version` to the new version.
* Files [hotspot-official.config](config/hotspot-official.config), [hotspot.config](config/hotspot.config), [openj9-official.config](config/openj9-official.config) and [openj9.config](config/openj9.config)
  * Update `Versions` to be the same as `supported_versions` from [common_functions.sh](common_functions.sh)
  * Add appropriate entries for each supported OS + Architecture combination. (You should be able to copy-paste from a previous release and change the version)
* [Jenkinsfile](Jenkinsfile)
  * Add entries for building the new version as per this [PR](https://github.com/AdoptOpenJDK/openjdk-docker/pull/531/files).

You should now be able to follow the steps from the Quarterly release as above.
