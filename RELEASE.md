

* Create a issue to track the progress of the docker release images using the "release template" issue.

* Check if the binaries of all arches are available
  * HotSpot (x86_64, ppc64le, s390x, arm32, aarch64)
    - It is common for hotspot arm32 and aarch64 builds to be delayed. 
	- The usual criteria is if the arm related builds are going to be available within a couple of days of the other builds, then we wait for the builds to become available before raising the PR at the official repo. If it is expected to take longer than 2 days, we push the remaining arches right away, alerting the official maintainers of possible breakage downstream.
  * OpenJ9  (x86_64, ppc64le, s390x)

Non-Official Images


Official Images

Official images are maintained by the Docker community and updates are done through the official github repo at .... This requires an update to the Dockerfiles in this repo and a subsequent PR at the official repo with the commit id that has all the Dockerfile updates.

  * Generate the updated dockerfiles
    - `./update_all.sh`

  * If there are arches for which builds are missing you should see warnings such as this
    ```
    Parent version not matching for arch aarch64: jdk8u275-b01, jdk8u282-b08
    Parent version not matching for arch armv7l: jdk8u275-b01, jdk8u282-b08
    ```

    In the above example, This means that for aarch64 and armv7l, builds of the latest version (jdk8u282-b08) are not yet available.

  * Raise a PR for the updated Dockerfiles.

  * Once the PR is merged, generate the updated files for raising the PR at the official repo.
    - `./dockerhub_doc_config_update.sh`

  * The file `adoptopenjdk` can be mostly copied over to `library/adoptopenjdk` at the official repo. 
    - OS tags may need to be updated if there are OS version changes (This is not automated)
    - Ensure we are not removing any arches / OSes that are currently active and only the versions are changing / added.

  * PRs pending related to this at the Adopt repo.
    - Add script to update dockerfiles on a PR merge [PR #466]


Non-Official Images

Non-official images are maintained by the AdoptOpenJDK community primarily through this repo. The images are automatically updated by the nightly builds.

  * Ideally it is best to stop automated nightly builds (which also build release images) from running during the duration of the release. This is needed as the release tarballs for different arches trickle in and cause inconsistencies in the manifest entries.

  * Manually trigger the nightly build once the required arch builds for a release are available.

  * Re-enable automated nightly builds once all the release builds are pushed to DockerHub from the previous step.
