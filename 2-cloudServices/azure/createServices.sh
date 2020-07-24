#!/bin/bash

export AZ_RESOURCE_GROUP=ACM_RG
export AKS_CLUSTER_NAME=k8s-demo-cl
export AKS_CLUSTER_VERSION="1.16.10"
export AKS_CLUSTER_LOCATION=eastus
export AZ_VM_NAME=dtactivegate
export AZ_VM_LOCATION=westus

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
az vm create --name $AZ_VM_NAME --resource_group $AZ_RESOURCE_GROUP --location $AZ_VM_LOCATION --image UbuntuLTS --os-disk-size-gb 10 --os-disk-name $AZ_VM_NAME --size Standard_B2s
gcloud compute instances create --machine-type=n1-standard-2 --metadata=tenant_id=$DT_TENANTID,environment_id=$DT_ENVIRONMENTID,paas_token=$DT_PAAS_TOKEN --metadata-from-file startup-script=../../3-dynatrace/envActiveGate/installEnvActiveGate.sh  --boot-disk-type=pd-standard --reservation-affinity=any

INFO=./servicesInfo.json

rm $INFO 2>/dev/null
cat ./servicesInfo.sav | sed 's~AZRESOURCEGROUP~'"$AZ_RESOURCE_GROUP"'~' |
    sed 's~ZONEVM~'"$ZONEVM"'~' |
    sed 's~K8SCLUSTERNAME~'"$CLUSTER_NAME"'~' |
    sed 's~VMNAME~'"$VM_NAME"'~' |
    sed 's~PROJECTID~'"$PROJECT_ID"'~' >>$INFO
