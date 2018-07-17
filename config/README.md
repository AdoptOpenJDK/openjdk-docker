# Config files
Configuration files used by the docker image creation scripts.

### Files and what they are used for

* hotspot.config
  - Contains supported hotspot versions, architectures, OSes, builds and build types.
* openj9.config
  - Contains supported Eclipse OpenJ9 versions, architectures, OSes, builds and build types.
* tags.config
  - List of expandable tags for each combination of OS, build and build types. 
* slim-java_rtjar_del.list
  - List of rt.jar classes that will be deleted to create the slim image.
* slim-java_rtjar_keep.list
  - List of rt.jar classes that will be retained in the slim image.
* slim-java_jmod_del.list
  - List of jmod files that will be deleted to create the slim images.
* test_buckets.list
  - List of individual test functions. These test functions are currently part of test_multiarch.sh
* test_image_types_all.list
  - List of all docker image types.
* test_image_types.list
  - List of docker image types that will be tested in the current run.
