#!/usr/bin/env groovy

def build_shell='''
rm -rf openjdk-docker \
&& git clone https://github.com/jonpspri/openjdk-docker.git \
&& cd openjdk-docker \
&& git checkout multi-arch \
&& ./build_all.sh
'''

def manifest_shell='''
cd openjdk-docker \
&& ./update_manifest_all.sh
'''

pipeline {
  parameters {
    string(
      name: 'ADOPTOPENJDK_TARGET_REGISTRY',
      defaultValue: 'adoptopenjdk',
      description: """
      The docker registry into which the docker images should be placed.
      Defaults to 'adoptopenjdk' (on docker.io).  One potential alternative
      could be 'registry.ng.bluemix.net/adoptopenjdk'.
      """
      )
  }
  agent none
  stages {
    stage('Build') {
      parallel {
        stage("Build-x86_64") {
          agent {
            label "docker-x86_64"
          }
          steps {
            sh build_shell
          }
        }
        stage("Build-s390x") {
          agent {
            label "docker-s390x"
          }
          steps {
            sh build_shell
          }
        }
        stage("Build-aarch64") {
          agent {
            label "docker-aarch64"
          }
          steps {
            sh build_shell
          }
        }
        stage("Build-ppc64le") {
          agent {
            label "docker-ppc64le"
          }
          steps {
            sh build_shell
          }
        }

      }
    }
    stage("Manifest") {
      agent {
        // Could be anything capable of running 'docker manifest', but right
        // now only the x86_64 environment is set up for that.
        label "docker-x86_64"
      }
      steps {
        sh manifest_shell
      }
    }
  }
}
