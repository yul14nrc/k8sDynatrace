#!/bin/bash

exec > >(tee -i ./createGKECluster.log)
exec 2>&1

NUMBER=$(shuf -i 200000-300000 -n 1)

PROJECT_NAME=project-demo
PROJECT_ID=${PROJECT_NAME}-${NUMBER}
CLUSTER_NAME=k8s-demo-cl
ZONE=us-central1-a
REGION=us-central1
GKE_VERSION="1.15"

echo ""
echo "---------------------------------------------------------------"
echo "The GKE Cluster will be created with the following information:"
echo "---------------------------------------------------------------"
echo ""
echo "Project Name: "$PROJECT_NAME
echo "Project ID: "$PROJECT_ID
echo "Cluster Name: "$CLUSTER_NAME
echo "Zone: "$ZONE
echo "Region: "$REGION
echo "GKE Version: "$GKE_VERSION
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
gcloud container clusters create $CLUSTER_NAME --zone $ZONE --cluster-version $GKE_VERSION --num-nodes=3 --machine-type=n1-highmem-2 --image-type "UBUNTU" --no-enable-ip-alias --no-enable-autoupgrade
echo ""
echo "-------------------------------------------------"
echo "Creating GKE ClusterRoleBinding for '"$CLUSTER_NAME"'"
echo "-------------------------------------------------"
echo ""
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)
echo ""
