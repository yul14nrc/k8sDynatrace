#!/bin/bash
echo ""
echo "----------------------------------------------------------------------"
echo "The GKE Cluster and VM will be created with the following information:"
echo "----------------------------------------------------------------------"
echo ""
echo "Project Name: "$PROJECT_NAME
echo "Project ID: "$PROJECT_ID
echo "Cluster Name: "$CLUSTER_NAME
echo "Zone k8s Cluster: "$ZONEK8SCL
echo "GKE Version: "$K8S_VERSION
echo ""
echo "-------------------------------------------------"
echo "Checking if project '"$PROJECT_ID"' on GCP exists"
echo "-------------------------------------------------"
echo ""
GCP_PROJECT_LIST=$(gcloud projects list --format="json" --filter="$PROJECT_ID")
GCP_PROJECT_LIST_LENGHT=$(echo $GCP_PROJECT_LIST | jq -r '. | length')
if [[ $GCP_PROJECT_LIST_LENGHT -eq 0 ]]; then
    echo "GCP Project '"$PROJECT_ID"' does not exists..."
    echo ""
    echo "---------------------------------------"
    echo "Creating project '"$PROJECT_ID"' on GCP"
    echo "---------------------------------------"
    echo ""
    gcloud projects create $PROJECT_ID --name=\"$PROJECT_NAME\" --no-enable-cloud-apis
    echo ""
    GCP_PROJECT_CREATED=true
    echo "-------------------------------------------------------------------------"
    echo "Linking billing account with project '"$PROJECT_ID"' and enabling GKE API"
    echo "-------------------------------------------------------------------------"
    echo ""
    ACCOUNT_ID=$(gcloud alpha billing accounts list --format="value(ACCOUNT_ID)" --filter="OPEN=True")
    gcloud beta billing projects link $PROJECT_ID --billing-account=$ACCOUNT_ID
    echo ""
    echo "---------------------------------------------------------"
    echo "Setting project '"$PROJECT_ID"' as current project on GCP"
    echo "---------------------------------------------------------"
    echo ""
    gcloud config set project $PROJECT_ID
    echo ""
    echo "---------------------------------------------------------"
    echo "Enabling compute and container apis in project '"$PROJECT_ID"'"
    echo "---------------------------------------------------------"
    sleep 15
    gcloud services enable compute.googleapis.com --project=$PROJECT_ID
    gcloud services enable container.googleapis.com --project=$PROJECT_ID
fi
echo ""
echo "--------------------------------------"
echo "Creating GKE Cluster '"$CLUSTER_NAME"'"
echo "--------------------------------------"
echo ""
gcloud container clusters create $CLUSTER_NAME --zone $ZONEK8SCL --cluster-version $K8S_VERSION --num-nodes=2 --machine-type=n1-highmem-4 --image-type "cos_containerd" --no-enable-ip-alias --no-enable-autoupgrade
echo ""
echo "-----------------------------------------------------"
echo "Creating GKE ClusterRoleBinding for '"$CLUSTER_NAME"'"
echo "-----------------------------------------------------"
echo ""
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account) --kubeconfig ~/.kube/config
if [[ $AG_TYPE == "1" ]];then
    echo "------------------------------------------------------"
    echo "The VM will be created with the following information:"
    echo "------------------------------------------------------"
    echo ""
    echo "Project Name: "$PROJECT_NAME
    echo "Project ID: "$PROJECT_ID
    echo "VM Name: "$VM_NAME
    echo "Zone VM: "$ZONEVM
    echo ""
    echo "------------------------"
    echo "Creating VM '"$VM_NAME"'"
    echo "------------------------"
    echo ""
    if [[ $DT_TYPE == "1" ]];then
        gcloud compute instances create $VM_NAME --zone=$ZONEVM --machine-type=n1-standard-1 --metadata=tenant_id=$DT_TENANTID,environment_id=$DT_ENVIRONMENTID,api_token=$DT_API_TOKEN --metadata-from-file startup-script=../../3-dynatrace/envActiveGate/installEnvActiveGate.sh --image=ubuntu-minimal-2004-focal-v20240426 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=$VM_NAME --reservation-affinity=any
    else
        gcloud compute instances create $VM_NAME --zone=$ZONEVM --machine-type=n1-standard-1 --image=ubuntu-minimal-2004-focal-v20220910 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=$VM_NAME --reservation-affinity=any
    fi
    AGTYPE=external
else
    VM_NAME=""
    ZONEVM=""
    AGTYPE=internal
fi
if [[ $DT_TYPE == "1" ]];then
    DTTYPE=true
else
    DTTYPE=false
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
    sed 's~PROJECTID~'"$PROJECT_ID"'~' |
    sed 's~DYNATRACEDEPLOY~'"$DTTYPE"'~' >>$INFO