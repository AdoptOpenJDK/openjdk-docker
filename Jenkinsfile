@Library('tivoPipeline') _

emailBreaks {
    node('docker') {
        stage('Code Checkout'){
            checkout scm
        }
        stage('Build Docker Images') {
            docker.withRegistry('https://docker.tivo.com', 'docker-registry') {
                                
                // build images for service images
                dir('8/jre/alpine') {
                    def image = docker.build("docker.tivo.com/openjdk8:alpine-jre", "-f Dockerfile.hotspot.releases.full --pull .")
                    image.push()
                }
                dir('8/jdk/alpine') {
                    def image = docker.build("docker.tivo.com/openjdk8:alpine", "-f Dockerfile.hotspot.releases.full --pull .")
                    image.push()
                }
                dir('8/jdk/alpine') {
                    def image = docker.build("docker.tivo.com/openjdk8:alpine-slim", "-f Dockerfile.hotspot.releases.slim --pull .")
                    image.push()
                }
                dir('11/jre/alpine') {
                    def image = docker.build("docker.tivo.com/openjdk11:alpine-jre", "-f Dockerfile.hotspot.releases.full --pull .")
                    image.push()
                }
                dir('11/jdk/alpine') {
                    def image = docker.build("docker.tivo.com/openjdk11:alpine", "-f Dockerfile.hotspot.releases.full --pull .")
                    image.push()
                }
                dir('11/jdk/alpine') {
                    def image = docker.build("docker.tivo.com/openjdk11:alpine-slim", "-f Dockerfile.hotspot.releases.slim --pull .")
                    image.push()
                }

                // build images for jenkins builds
                dir('8/jdk/ubuntu') {
                    def image = docker.build("docker.tivo.com/openjdk8:ubuntu-p4", "-f Dockerfile.hotspot.releases.full.p4 --pull .")
                    image.push()
                }
                dir('11/jdk/ubuntu') {
                    def image = docker.build("docker.tivo.com/openjdk11:ubuntu-p4", "-f Dockerfile.hotspot.releases.full.p4 --pull .")
                    image.push()
                }
            }
        }
    }
}
