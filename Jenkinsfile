@Library('tivoPipeline') _

emailBreaks {
    node('docker') {
        stage('Code Checkout'){
            git 'https://github.com/TiVo/openjdk-docker.git'
        }
        stage('Build Docker Images') {
            docker.withRegistry('https://docker.tivo.com', 'docker-registry') {
                dir('8/jre/alpine') {
                    def image = docker.build("docker.tivo.com/alpine-java:8_server-jre", "-f Dockerfile.hotspot.releases.full --pull .")
                    image.push()
                }
                dir('8/jdk/alpine') {
                    def image = docker.build("docker.tivo.com/alpine-java:8_jdk", "-f Dockerfile.hotspot.releases.full --pull .")
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
            }
        }
    }
}
