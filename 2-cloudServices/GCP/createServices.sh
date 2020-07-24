#!/bin/bash

#exec > >(tee -i ./createGKECluster.log)
#exec 2>&1

NUMBER=$(shuf -i 200000-300000 -n 1)

PROJECT_NAME=project-demo
PROJECT_ID=${PROJECT_NAME}-${NUMBER}
CLUSTER_NAME=k8s-demo-cl
ZONEK8SCL=us-central1-a
ZONEVM=us-east1-b
GKE_VERSION="1.15"
VM_NAME=dtactivegate

echo ""
echo "---------------------------------------------------------------"
echo "The GKE Cluster and VM will be created with the following information:"
echo "---------------------------------------------------------------"
echo ""
echo "Project Name: "$PROJECT_NAME
echo "Project ID: "$PROJECT_ID
echo "Cluster Name: "$CLUSTER_NAME
echo "Zone k8s Cluster: "$ZONEK8SCL
echo "Zone VM: "$ZONEVM
echo "GKE Version: "$GKE_VERSION
echo "VM Name: "$VM_NAME
echo ""
echo "------------------------------"
echo "Creating environment variables"
echo "------------------------------"
echo ""
echo "export CLUSTER_NAME=$CLUSTER_NAME"
echo ""
echo "-----------------------------------------"
echo "Creating project '"$PROJECT_NAME"' on GCP"
echo "-----------------------------------------"
echo ""
gcloud projects create $PROJECT_ID --name=\"$PROJECT_NAME\" --no-enable-cloud-apis
echo ""
echo "-----------------------------------------------------------"
echo "Setting project '"$PROJECT_NAME"' as current project on GCP"
echo "-----------------------------------------------------------"
echo ""
gcloud config set project $PROJECT_ID
echo ""
echo "--------------------------------------------------------------------------"
echo "Linking billing account with project '"$PROJECT_NAME"' and enabling GKE API"
echo "--------------------------------------------------------------------------"
echo ""
ACCOUNT_ID=$(gcloud alpha billing accounts list --format="value(ACCOUNT_ID)" --filter="OPEN=True")
gcloud beta billing projects link $PROJECT_ID --billing-account=$ACCOUNT_ID
gcloud services enable container.googleapis.com
echo ""
echo "--------------------------------------"
echo "Creating GKE Cluster '"$CLUSTER_NAME"'"
echo "--------------------------------------"
echo ""
gcloud container clusters create $CLUSTER_NAME --zone $ZONEK8SCL --cluster-version $GKE_VERSION --num-nodes=2 --machine-type=n1-highmem-4 --image-type "UBUNTU" --no-enable-ip-alias --no-enable-autoupgrade
echo ""
echo "-------------------------------------------------"
echo "Creating GKE ClusterRoleBinding for '"$CLUSTER_NAME"'"
echo "-------------------------------------------------"
echo ""
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)
echo ""
echo "--------------------------------------"
echo "Creating VM '"$VM_NAME"'"
echo "--------------------------------------"
echo ""
gcloud compute instances create $VM_NAME --zone=$ZONEVM --machine-type=n1-standard-1 --metadata=tenant_id=$DT_TENANTID,environment_id=$DT_ENVIRONMENTID,paas_token=$DT_PAAS_TOKEN --metadata-from-file startup-script=../../3-dynatrace/envActiveGate/installEnvActiveGate.sh --image=ubuntu-minimal-2004-focal-v20200702 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=$VM_NAME --reservation-affinity=any

INFO=./servicesInfo.json

rm $INFO 2>/dev/null
cat ./servicesInfo.sav | sed 's~ZONEK8SCL~'"$ZONEK8SCL"'~' |
    sed 's~ZONEVM~'"$ZONEVM"'~' |
    sed 's~K8SCLUSTERNAME~'"$CLUSTER_NAME"'~' |
    sed 's~VMNAME~'"$VM_NAME"'~' |
    sed 's~PROJECTID~'"$PROJECT_ID"'~' >>$INFO
