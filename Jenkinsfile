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
                        dockerBuild(null)
                    }
                }
                stage('Linux aarch64') {
                    agent {
                        label "dockerBuild&&linux&&aarch64"
                    }
                    steps {
                        dockerBuild(null)
                    }
                }
                stage('Linux armv7l 8') {
                    agent {
                        label "dockerBuild&&linux&&x64"
                    }
                    environment {
                        DOCKER_CLI_EXPERIMENTAL = "enabled"
                        TARGET_ARCHITECTURE = "linux/arm/v7" // defined in buildx https://www.docker.com/blog/multi-platform-docker-builds/
                    }
                    steps {
                        // Setup docker for multiarch builds
                        sh label: 'qemu-user', script: 'sudo apt-get -y install qemu-user'
                        sh label: 'docker-qemu', script: 'docker run --rm --privileged multiarch/qemu-user-static --reset -p yes'
                        dockerBuild(8)
                    }
                }
                stage('Linux armv7l 11') {
                    agent {
                        label "dockerBuild&&linux&&x64"
                    }
                    environment {
                        DOCKER_CLI_EXPERIMENTAL = "enabled"
                        TARGET_ARCHITECTURE = "linux/arm/v7" // defined in buildx https://www.docker.com/blog/multi-platform-docker-builds/
                    }
                    steps {
                        // Setup docker for multiarch builds
                        sh label: 'qemu-user', script: 'sudo apt-get -y install qemu-user'
                        sh label: 'docker-qemu', script: 'docker run --rm --privileged multiarch/qemu-user-static --reset -p yes'
                        dockerBuild(11)
                    }
                }
                stage('Linux armv7l 14') {
                    agent {
                        label "dockerBuild&&linux&&x64"
                    }
                    environment {
                        DOCKER_CLI_EXPERIMENTAL = "enabled"
                        TARGET_ARCHITECTURE = "linux/arm/v7" // defined in buildx https://www.docker.com/blog/multi-platform-docker-builds/
                    }
                    steps {
                        // Setup docker for multiarch builds
                        sh label: 'qemu-user', script: 'sudo apt-get -y install qemu-user'
                        sh label: 'docker-qemu', script: 'docker run --rm --privileged multiarch/qemu-user-static --reset -p yes'
                        dockerBuild(14)
                    }
                }
                stage('Linux armv7l 15') {
                    agent {
                        label "dockerBuild&&linux&&x64"
                    }
                    environment {
                        DOCKER_CLI_EXPERIMENTAL = "enabled"
                        TARGET_ARCHITECTURE = "linux/arm/v7" // defined in buildx https://www.docker.com/blog/multi-platform-docker-builds/
                    }
                    steps {
                        // Setup docker for multiarch builds
                        sh label: 'qemu-user', script: 'sudo apt-get -y install qemu-user'
                        sh label: 'docker-qemu', script: 'docker run --rm --privileged multiarch/qemu-user-static --reset -p yes'
                        dockerBuild(15)
                    }
                }
                stage('Linux ppc64le') {
                    agent {
                        label "dockerBuild&&linux&&ppc64le"
                    }
                    steps {
                        dockerBuild(null)
                    }
                }
                stage('Linux s390x') {
                    agent {
                        label "docker&&linux&&s390x"
                    }
                    steps {
                        dockerBuild(null)
                    }
                }
            }
        }
        stage('Docker Manifest') {
            parallel {
                stage("Manifest 8") {
                    agent {
                        label "dockerBuild&&linux&&x64"
                    }
                    environment {
                    DOCKER_CLI_EXPERIMENTAL = "enabled"
                    }
                    steps {
                        dockerManifest(8)
                    }
                }
                stage("Manifest 11") {
                    agent {
                        label "dockerBuild&&linux&&x64"
                    }
                    environment {
                    DOCKER_CLI_EXPERIMENTAL = "enabled"
                    }
                    steps {
                        dockerManifest(11)
                    }
                }
                stage("Manifest 14") {
                    agent {
                        label "dockerBuild&&linux&&x64"
                    }
                    environment {
                    DOCKER_CLI_EXPERIMENTAL = "enabled"
                    }
                    steps {
                        dockerManifest(14)
                    }
                }
                stage("Manifest 15") {
                    agent {
                        label "dockerBuild&&linux&&x64"
                    }
                    environment {
                    DOCKER_CLI_EXPERIMENTAL = "enabled"
                    }
                    steps {
                        dockerManifest(15)
                    }
                }
            }
        }
    }
}

def dockerBuild(version) {
    // dockerhub is the ID of the credentials stored in Jenkins
    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub') {
        git poll: false, url: 'https://github.com/AdoptOpenJDK/openjdk-docker.git'
        if (version){
            sh label: '', script: "./build_all.sh ${version}"
        } else {
            sh label: '', script: "./build_all.sh"
        }
    }
}

def dockerManifest(version) {
    // dockerhub is the ID of the credentials stored in Jenkins
    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub') {
        git poll: false, url: 'https://github.com/AdoptOpenJDK/openjdk-docker.git'
        sh label: '', script: "./update_manifest_all.sh ${version}"
    }
}
