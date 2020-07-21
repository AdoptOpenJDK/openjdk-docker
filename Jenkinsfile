pipeline {
    agent none
    stages {
        stage('Docker Build') {
            parallel {
                stage('Linux x64') {
                    agent {
                        label "dockerBuild&&linux&&x64"
                    }
                    steps {
                        dockerBuild()
                    }
                }
                stage('Linux aarch64') {
                    agent {
                        label "dockerBuild&&linux&&aarch64"
                    }
                    steps {
                        dockerBuild()
                    }
                }
                stage('Linux armv7l') {
                    agent {
                        label "docker&&linux&&armv7l"
                    }
                    steps {
                        dockerBuild()
                    }
                }
                stage('Linux ppc64le') {
                    agent {
                        label "docker&&linux&&ppc64le"
                    }
                    steps {
                        dockerBuild()
                    }
                }
                stage('Linux s390x') {
                    agent {
                        label "docker&&linux&&s390x"
                    }
                    steps {
                        dockerBuild()
                    }
                }
            }
        }
        stage('Docker Manifest') {
            agent {
                label "dockerBuild&&linux&&x64"
            }
            environment {
               DOCKER_CLI_EXPERIMENTAL = "enabled"
            }
            steps {
                dockerManifest()
            }
        }
    }
}

def dockerBuild() {
    // dockerhub is the ID of the credentials stored in Jenkins
    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub') {
        git poll: false, url: 'https://github.com/AdoptOpenJDK/openjdk-docker.git'
        sh label: '', script: './build_all.sh'
    }
}

def dockerManifest() {
    // dockerhub is the ID of the credentials stored in Jenkins
    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub') {
        git poll: false, url: 'https://github.com/AdoptOpenJDK/openjdk-docker.git'
        sh label: '', script: './update_manifest_all.sh'
    }
}
