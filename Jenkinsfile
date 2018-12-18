/*
 * This file makes two assumptions about your Jenkins build environment:
 *
 * 1.  You have nodes set up with labels of the form "docker-${ARCH}" to
 *     support the various build architectures (currently 'x86_64',
 *     's390x', 'aarch64' (ARM), and 'ppc64le').
 * 2.  If you do not want to target the 'docker.io/adoptopenjdk' registry
 *     (and unless you're the official maintainer, you shouldn't), then
 *     you've set up an ADOPTOPENJDK_TARGET_REGISTRY variable with the target
 *     registry you'll use (for example 'localhost:5050/adoptopenjdk').
 *
 * TODO:  Add option for an insecure registry flag to the scripts.
 *
 * TODO:  Set up the build architectures as a parameter that will drive
 *        a scripted loop to build stages.
 */

def build_shell='''
./build_all.sh
'''

def manifest_shell='''
./update_manifest_all.sh
'''

pipeline {
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
