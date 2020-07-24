#!/bin/bash

export AZ_RESOURCE_GROUP=$(cat ../../2-cloudServices/azure/servicesInfo.json | jq -r '.azresourcegroup')
export ZONEVM=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.zoneVM')
export K8SCLUSTERNAME=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.k8sClusterName')
export VMNAME=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.vmName')
export PROJECTID=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.projectID')

gcloud container clusters delete $K8SCLUSTERNAME --zone $ZONEK8SCL --quiet

gcloud compute instances delete $VMNAME --zone $ZONEVM --quiet

az group delete --name $AZ_RESOURCE_GROUP --yes --no-wait
