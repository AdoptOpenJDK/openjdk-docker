#/bin/bash
# first run these commands in your shell
#az login
#az account set --subscription 5582a4f8-8f93-4e4e-b64c-5a123af91d3f
#az acr login --name dmdevacr01
# Build Nvidia image with JVM slim
az acr build --file Dockerfile.hotspot.releases.slim --image datomizer/spark-nvidia-jdk11:{{.Run.ID}} --registry DMDevACR01 --resource-group dm-dev-test-01 .
