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
echo "The GKE Cluster and VM will be created with the following information:"
echo "----------------------------------------------------------------------"
echo ""
echo "Project Name: "$PROJECT_NAME
echo "Project ID: "$PROJECT_ID
echo "Cluster Name: "$CLUSTER_NAME
echo "Zone k8s Cluster: "$ZONEK8SCL
echo "Zone VM: "$ZONEVM
echo "GKE Version: "$K8S_VERSION
echo "VM Name: "$VM_NAME
echo ""
echo "-------------------------------------------------"
echo "Checking if project '"$PROJECT_ID"' on GCP exists"
echo "-------------------------------------------------"
echo ""
GCP_PROJECT_LIST=$(gcloud projects list --format="json" --filter="$PROJECT_ID")
for ((j = 0; j <= $(echo $GCP_PROJECT_LIST | jq -r '. | length') - 1; j++)); do
    GCP_PROJECT_ID=$(echo $GCP_PROJECT_LIST | jq -r '.['$j'].projectId')
    if [[ $GCP_PROJECT_ID == $PROJECT_ID ]]; then
        echo "GCP Project "$PROJECT_ID" exists..."
        j=$(echo $GCP_PROJECT_LIST | jq -r '. | length')
        GCP_PROJECT_CREATED=false
    else
        echo "GCP Project "$PROJECT_ID" does not exists..."
        echo ""
        echo "---------------------------------------"
        echo "Creating project '"$PROJECT_ID"' on GCP"
        echo "---------------------------------------"
        echo ""
        gcloud projects create $PROJECT_ID --name=\"$PROJECT_NAME\" --no-enable-cloud-apis
        GCP_PROJECT_CREATED=true
        echo "-------------------------------------------------------------------------"
        echo "Linking billing account with project '"$PROJECT_ID"' and enabling GKE API"
        echo "-------------------------------------------------------------------------"
        echo ""
        ACCOUNT_ID=$(gcloud alpha billing accounts list --format="value(ACCOUNT_ID)" --filter="OPEN=True")
        gcloud beta billing projects link $PROJECT_ID --billing-account=$ACCOUNT_ID
        gcloud services enable container.googleapis.com
    fi
done
echo ""
echo "---------------------------------------------------------"
echo "Setting project '"$PROJECT_ID"' as current project on GCP"
echo "---------------------------------------------------------"
echo ""
gcloud config set project $PROJECT_ID
echo ""
echo "--------------------------------------"
echo "Creating GKE Cluster '"$CLUSTER_NAME"'"
echo "--------------------------------------"
echo ""
gcloud container clusters create $CLUSTER_NAME --zone $ZONEK8SCL --cluster-version $K8S_VERSION --num-nodes=2 --machine-type=n1-highmem-4 --image-type "UBUNTU" --no-enable-ip-alias --no-enable-autoupgrade
echo ""
echo "-----------------------------------------------------"
echo "Creating GKE ClusterRoleBinding for '"$CLUSTER_NAME"'"
echo "-----------------------------------------------------"
echo ""
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account) --kubeconfig ~/.kube/config
if [[ $AG_TYPE == "1" ]];then
    echo ""
    echo "------------------------"
    echo "Creating VM '"$VM_NAME"'"
    echo "------------------------"
    echo ""
    gcloud compute instances create $VM_NAME --zone=$ZONEVM --machine-type=n1-standard-1 --metadata=tenant_id=$DT_TENANTID,environment_id=$DT_ENVIRONMENTID,api_token=$DT_API_TOKEN --metadata-from-file startup-script=../../3-dynatrace/envActiveGate/installEnvActiveGate.sh --image=ubuntu-minimal-2004-focal-v20220910 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=$VM_NAME --reservation-affinity=any
    AGTYPE=external
else
    VM_NAME=""
    ZONEVM=""
    AGTYPE=internal
fi

if [[ $GCP_PROJECT_CREATED == false ]]; then
    PROJECT_ID=""
fi

INFO=./servicesInfo.json

rm $INFO 2>/dev/null
cat ./servicesInfo.sav | sed 's~K8SCLUSTERNAME~'"$CLUSTER_NAME"'~' |
    sed 's~ZONEK8SCL~'"$ZONEK8SCL"'~' |
    sed 's~VMNAME~'"$VM_NAME"'~' |
    sed 's~ZONEVM~'"$ZONEVM"'~' |
    sed 's~AGTYPE~'"$AGTYPE"'~' |
    sed 's~PROJECTID~'"$PROJECT_ID"'~' >>$INFO