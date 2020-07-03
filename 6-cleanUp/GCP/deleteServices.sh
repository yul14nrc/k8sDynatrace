#!/bin/bash

export ZONE=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.zone')
export K8SCLUSTERNAME=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.k8sClusterName')
export VMNAME=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.vmName')
export PROJECTID=$(cat ../../2-cloudServices/GCP/servicesInfo.json | jq -r '.projectID')

gcloud container clusters delete $K8SCLUSTERNAME --zone $ZONE

gcloud compute instances delete dtactivegate --zone $ZONE

gcloud projects delete $PROJECTID --quiet
