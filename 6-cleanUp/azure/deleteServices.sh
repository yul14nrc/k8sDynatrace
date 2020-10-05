#!/bin/bash

export AZ_APPID=$(cat ../../2-cloudServices/azure/azureServicePrincipalInfo.json | jq -r '.appId')

export AZ_RESOURCE_GROUP=$(cat ../../2-cloudServices/azure/servicesInfo.json | jq -r '.azresourcegroup')

az ad sp delete --id $AZ_APPID

az group delete --name $AZ_RESOURCE_GROUP --yes --no-wait
