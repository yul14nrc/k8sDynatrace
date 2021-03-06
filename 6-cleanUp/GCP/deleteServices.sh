#!/bin/bash

export ZONEK8SCL=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.zonek8sCl')
export ZONEVM=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.zoneVM')
export K8SCLUSTERNAME=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.k8sClusterName')
export VMNAME=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.vmName')
export PROJECTID=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.projectID')

gcloud container clusters delete $K8SCLUSTERNAME --zone $ZONEK8SCL --quiet

gcloud compute instances delete $VMNAME --zone $ZONEVM --quiet

gcloud projects delete $PROJECTID --quiet
