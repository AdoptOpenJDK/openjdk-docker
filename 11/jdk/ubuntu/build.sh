#/bin/bash
# first run these commands in your shell
#az login
#az account set --subscription de11fcc2-c589-4276-bafa-50ec92a39434
#az acr login --name crappdev
# Build Nvidia image with JVM slim
cd 11/jdk/ubuntu
az acr build --file Dockerfile.hotspot.releases.slim --image datomizer/spark-nvidia-jdk11:{{.Run.ID}} --registry crappdev --resource-group rg-cr-dev-01 .
