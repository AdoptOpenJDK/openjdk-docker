#/bin/bash
# first run these commands in your shell
#az login
#az account set --subscription 19827096-9747-4941-a512-691966f8531b
#az acr login --name crappdev
# Build Nvidia image with JVM slim
cd 11/jdk/ubuntu
az acr build --file Dockerfile.hotspot.releases.slim --image datomizer/spark-nvidia-jdk11:{{.Run.ID}} --registry crappdev --resource-group rg-cr-dev-01 .
