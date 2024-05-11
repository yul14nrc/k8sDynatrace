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
fi

echo ""
echo "----------------------------------------------------------------------"
echo "The AKS Cluster and VM will be created with the following information:"
echo "----------------------------------------------------------------------"
echo ""
echo "Resource Group: "$RG_NAME
echo "Cluster Name: "$CLUSTER_NAME
echo "k8s Cluster Region: "$REGIONK8SCL
echo "AKS Version: "$K8S_VERSION
echo "VM Name: "$VM_NAME
echo "VM Region: "$REGIONVM
echo ""
echo "---------------------------------------------"
echo "Creating Resource Group '"$RG_NAME"' on Azure"
echo "---------------------------------------------"
echo ""
AZ_RG_LIST=$(az group list -o json)
for ((j = 0; j <= $(echo $AZ_RG_LIST | jq -r '. | length') - 1; j++)); do
    AZ_RG_NAME=$(echo $AZ_RG_LIST | jq -r '.['$j'].name')
    if [[ $AZ_RG_NAME == $RG_NAME ]]; then
        echo "Azure Resource Group "$RG_NAME" exists..."
        echo ""
        echo "Please specify another azure resource group to continue with the deployment..."
        exit 1
    else
        echo "Azure Resource Group "$RG_NAME" does not exists..."
        echo ""
        echo "------------------------------------"
        echo "Creating Resource Group '"$RG_NAME"'"
        echo "------------------------------------"
        echo ""
        az group create --name $RG_NAME --location $REGIONK8SCL
        j=$(echo $AZ_RG_LIST | jq -r '. | length')
    fi
done
echo ""
echo "--------------------------------------"
echo "Creating AKS Cluster '"$CLUSTER_NAME"'"
echo "--------------------------------------"
echo ""
az aks create --resource-group $RG_NAME --name $CLUSTER_NAME --kubernetes-version $K8S_VERSION --location $REGIONK8SCL --enable-addons monitoring --node-count 2 --node-vm-size Standard_B4ms --generate-ssh-keys --yes
echo ""
echo "---------------------------------------------"
echo "Getting AKS credentials for '"$CLUSTER_NAME"'"
echo "---------------------------------------------"
echo ""
az aks get-credentials --resource-group $RG_NAME --name $CLUSTER_NAME
echo ""
if [[ $AG_TYPE == "1" ]];then
    echo "------------------------------"
    echo "Creating Azure VM '"$VM_NAME"'"
    echo "------------------------------"
    echo ""
    az vm create --name $VM_NAME --resource-group $RG_NAME --location $REGIONVM --image UbuntuLTS --os-disk-size-gb 30 --os-disk-name $VM_NAME --size Standard_B2s --public-ip-sku Standard
    echo "-----------------------------------------------------"
    echo "Running script to install AG on Azure VM '"$VM_NAME"'"
    echo "-----------------------------------------------------"
    echo ""
    az vm run-command invoke --command-id RunShellScript --name $VM_NAME --resource-group $RG_NAME --script @../../3-dynatrace/envActiveGate/installEnvActiveGate.sh --parameters 'arg1='$DT_TENANTID'' 'arg2='$DT_API_TOKEN''
    AGTYPE=external
else
    VM_NAME=""
    REGIONVM=""
    AGTYPE=internal
fi

INFO=./servicesInfo.json

rm $INFO 2>/dev/null
cat ./servicesInfo.sav | sed 's~K8SCLUSTERNAME~'"$CLUSTER_NAME"'~' |
    sed 's~ZONEK8SCL~'"$REGIONK8SCL"'~' |
    sed 's~VMNAME~'"$VM_NAME"'~' |
    sed 's~ZONEVM~'"$REGIONVM"'~' |
    sed 's~AGTYPE~'"$AGTYPE"'~' |
    sed 's~RESOURCEGROUP~'"$RG_NAME"'~' >>$INFO
