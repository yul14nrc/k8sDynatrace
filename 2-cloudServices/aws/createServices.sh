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
echo "The EKS Cluster and VM will be created with the following information:"
echo "----------------------------------------------------------------------"
echo ""
echo "Cluster Name: "$CLUSTER_NAME
echo "k8s Cluster Region: "$REGIONK8SCL
echo "EKS Version: "$K8S_VERSION
echo "VM Name: "$VM_NAME
echo "VM Region: "$REGIONVM
echo ""
echo "--------------------------------------"
echo "Creating EKS Cluster '"$CLUSTER_NAME"'"
echo "--------------------------------------"
echo ""
eksctl create cluster -f cluster.yaml
echo ""


INFO=./servicesInfo.json

rm $INFO 2>/dev/null
cat ./servicesInfo.sav | sed 's~K8SCLUSTERNAME~'"$CLUSTER_NAME"'~' |
    sed 's~ZONEK8SCL~'"$REGIONK8SCL"'~' |
    sed 's~VMNAME~'"$VM_NAME"'~' |
    sed 's~ZONEVM~'"$REGIONVM"'~' |
    sed 's~AGTYPE~'"$AGTYPE"'~' |
    sed 's~RESOURCEGROUP~'"$RG_NAME"'~' >>$INFO
