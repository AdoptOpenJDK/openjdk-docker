#!/bin/bash

/opt/manifest_tool/cli/build/docker manifest create adoptopenjdk/openjdk11:windows 
/opt/manifest_tool/cli/build/docker manifest push adoptopenjdk/openjdk11:windows

/opt/manifest_tool/cli/build/docker manifest create adoptopenjdk/openjdk11:jdk-11.0.3_7 
/opt/manifest_tool/cli/build/docker manifest push adoptopenjdk/openjdk11:jdk-11.0.3_7

/opt/manifest_tool/cli/build/docker manifest create adoptopenjdk/openjdk11:windows-nightly 
/opt/manifest_tool/cli/build/docker manifest push adoptopenjdk/openjdk11:windows-nightly

/opt/manifest_tool/cli/build/docker manifest create adoptopenjdk/openjdk11:jdk11u-windows-nightly 
/opt/manifest_tool/cli/build/docker manifest push adoptopenjdk/openjdk11:jdk11u-windows-nightly

/opt/manifest_tool/cli/build/docker manifest create adoptopenjdk/openjdk11-openj9:windows 
/opt/manifest_tool/cli/build/docker manifest push adoptopenjdk/openjdk11-openj9:windows

/opt/manifest_tool/cli/build/docker manifest create adoptopenjdk/openjdk11-openj9:jdk-11.0.3_7_openj9-0.14.0 
/opt/manifest_tool/cli/build/docker manifest push adoptopenjdk/openjdk11-openj9:jdk-11.0.3_7_openj9-0.14.0

/opt/manifest_tool/cli/build/docker manifest create adoptopenjdk/openjdk11-openj9:windows-nightly 
/opt/manifest_tool/cli/build/docker manifest push adoptopenjdk/openjdk11-openj9:windows-nightly

/opt/manifest_tool/cli/build/docker manifest create adoptopenjdk/openjdk11-openj9:jdk11u-windows-nightly 
/opt/manifest_tool/cli/build/docker manifest push adoptopenjdk/openjdk11-openj9:jdk11u-windows-nightly

