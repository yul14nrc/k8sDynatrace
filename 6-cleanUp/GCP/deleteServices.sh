#!/bin/bash

export K8SCLUSTERNAME=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.k8sClusterName')
export ZONEK8SCL=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.zonek8sCl')
export VMNAME=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.vmName')
export ZONEVM=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.zoneVM')
export PROJECTID=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.projectID')

gcloud container clusters delete $K8SCLUSTERNAME --zone $ZONEK8SCL --quiet

if [[ $VMNAME != "" ]]; then
    gcloud compute instances delete $VMNAME --zone $ZONEVM --quiet
fi

if [[ $PROJECTID != "" ]]; then
    gcloud projects delete $PROJECTID --quiet
fi

FILE=../../2-cloudServices/GCP/servicesInfo.json
rm $FILE 2>/dev/null