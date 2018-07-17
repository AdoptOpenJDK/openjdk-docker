# Config files
Configuration files used by the docker image creation scripts.

### Files and what they are used for

* hotspot.config
  - Contains supported hotspot versions, architectures, OSes, builds and build types.
* openj9.config
  - Contains supported Eclipse OpenJ9 versions, architectures, OSes, builds and build types.
* tags.config
  - List of expandable tags for each combination of OS, build and build types. 
* slim-java\_rtjar\_del.list
  - List of rt.jar classes that will be deleted to create the slim image.
* slim-java\_rtjar\_keep.list
  - List of rt.jar classes that will be retained in the slim image.
* slim-java\_jmod\_del.list
  - List of jmod files that will be deleted to create the slim images.
* test\_buckets.list
  - List of individual test functions. These test functions are currently part of test\_multiarch.sh
* test\_image\_types\_all.list
  - List of all docker image types.
* test\_image\_types.list
  - List of docker image types that will be tested in the current run.
