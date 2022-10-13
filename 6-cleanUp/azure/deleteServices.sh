#!/bin/bash

export K8SCLUSTERNAME=$(cat ../../2-cloudServices/azure/servicesInfo.json | jq -r '.k8sClusterName')
export ZONEK8SCL=$(cat ../../2-cloudServices/azure/servicesInfo.json | jq -r '.zonek8sCl')
export VMNAME=$(cat ../../2-cloudServices/azure/servicesInfo.json | jq -r '.vmName')
export ZONEVM=$(cat ../../2-cloudServices/azure/servicesInfo.json | jq -r '.zoneVM')
export RESOURCEGROUP=$(cat ../../2-cloudServices/azure/servicesInfo.json | jq -r '.ResourceGroup')

#az ad sp delete --id $AZ_APPID

echo ""
echo "----------------------------------------"
echo "Deleting AKS Cluster '"$K8SCLUSTERNAME"'"
echo "----------------------------------------"
echo ""
az aks delete --name $K8SCLUSTERNAME --resource-group $RESOURCEGROUP --yes
if [[ $VMNAME != "" ]]; then
    echo "-----------------------"
    echo "Deleting Azure VM '"$VMNAME"'"
    echo "-----------------------"
    echo ""
    az vm delete --name $VMNAME --resource-group $RESOURCEGROUP --yes
fi

if [[ $RESOURCEGROUP != "" ]]; then
    echo "-----------------------------------------"
    echo "Deleting Azure Resource Group '"$RESOURCEGROUP"'"
    echo "-----------------------------------------"
    echo ""
    az group delete --name $RESOURCEGROUP --yes --no-wait
fi

kubectl config delete-context $K8SCLUSTERNAME

FILE=../../2-cloudServices/azure/servicesInfo.json
rm $FILE 2>/dev/null