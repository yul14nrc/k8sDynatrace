#!/bin/bash

if [ -z "$DT_TENANTID" ]; then

    export CREDS=../../1-credentials/creds.json

    if [ -f "$CREDS" ]; then
        echo "The $CREDS file exists."
    else
        echo "The $CREDS file does not exists. Executing the defineDTcredentials.sh script..."
        cd ../../1-credentials
        ./defineDTCredentials.sh
        cd ../3-dynatrace/connectK8sDynatrace
    fi

    export DT_TENANTID=$(cat ../../1-credentials/creds.json | jq -r '.dynatraceTenantID')
    export DT_ENVIRONMENTID=$(cat ../../1-credentials/creds.json | jq -r '.dynatraceEnvironmentID')
    export DT_API_TOKEN=$(cat ../../1-credentials/creds.json | jq -r '.dynatraceApiToken')
    export DT_PAAS_TOKEN=$(cat ../../1-credentials/creds.json | jq -r '.dynatracePaaSToken')
fi

AZ_RESOURCE_GROUP=ACM_RG
AKS_CLUSTER_NAME=k8s-demo-cl
AKS_CLUSTER_VERSION="1.16.10"
AKS_CLUSTER_LOCATION=eastus
AZ_VM_NAME=dtactivegate
AZ_VM_LOCATION=westus2

echo ""
echo "----------------------------------------------------------------------"
echo "The AKS Cluster and VM will be created with the following information:"
echo "----------------------------------------------------------------------"
echo ""
echo "Resource Group: "$AZ_RESOURCE_GROUP
echo "Cluster Name: "$AKS_CLUSTER_NAME
echo "Location k8s Cluster: "$AKS_CLUSTER_LOCATION
echo "GKE Version: "$AKS_CLUSTER_VERSION
echo "VM Name: "$AZ_VM_NAME
echo "Zone VM: "$AZ_VM_LOCATION
echo ""
echo "-----------------------------------------"
echo "Creating Resource Group '"$AZ_RESOURCE_GROUP"' on Azure"
echo "-----------------------------------------"
echo ""
az group create --name $AZ_RESOURCE_GROUP --location centralus
echo ""
echo "--------------------------------------"
echo "Creating AKS Cluster '"$AKS_CLUSTER_NAME"'"
echo "--------------------------------------"
echo ""
az aks create --resource-group $AZ_RESOURCE_GROUP --name $AKS_CLUSTER_NAME --kubernetes-version $AKS_CLUSTER_VERSION --location $AKS_CLUSTER_LOCATION --enable-addons monitoring --node-count 2 --node-vm-size Standard_B4ms --generate-ssh-keys
echo ""
echo "-------------------------------------------------"
echo "Getting AKS credentials for '"$AKS_CLUSTER_NAME"'"
echo "-------------------------------------------------"
echo ""
az aks get-credentials --resource-group $AZ_RESOURCE_GROUP --name $AKS_CLUSTER_NAME
echo ""
echo "--------------------------------------"
echo "Creating Azure VM '"$AZ_VM_NAME"'"
echo "--------------------------------------"
echo ""
az vm create --name $AZ_VM_NAME --resource-group $AZ_RESOURCE_GROUP --location $AZ_VM_LOCATION --image UbuntuLTS --os-disk-size-gb 30 --os-disk-name $AZ_VM_NAME --size Standard_B2s
echo "--------------------------------------"
echo "Deploying extension to Azure VM '"$AZ_VM_NAME"'"
echo "--------------------------------------"
echo ""
az vm extension set --resource-group $AZ_RESOURCE_GROUP --vm-name $AZ_VM_NAME --name customScript --publisher Microsoft.Azure.Extensions --settings '{"fileUris": ["https://raw.githubusercontent.com/yul14nrc/k8sDynatrace/master/3-dynatrace/envActiveGate/installEnvActiveGate.sh"],"commandToExecute": "./installEnvActiveGate.sh '$DT_TENANTID' '$DT_PAAS_TOKEN'"}'

INFO=./servicesInfo.json

rm $INFO 2>/dev/null
cat ./servicesInfo.sav | sed 's~AZRESOURCEGROUP~'"$AZ_RESOURCE_GROUP"'~' |
    sed 's~ZONEVM~'"$AZ_VM_LOCATION"'~' |
    sed 's~K8SCLUSTERNAME~'"$AKS_CLUSTER_NAME"'~' |
    sed 's~VMNAME~'"$AZ_VM_NAME"'~' >>$INFO
