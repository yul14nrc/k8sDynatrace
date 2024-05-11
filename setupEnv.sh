#!/bin/bash

export CLUSTER_NAME=k8s-demo-cl
export K8S_VERSION="1.28"
export VM_NAME=dtactivegate

if [ "$#" -ne 3 ]; then
    echo ""
    echo "No supported Cloud Provider (gcp or azure or aws) detected, AG deployment type or Dynatrace deployment."
    echo ""
    echo "usage: setupEnv.sh <gcp|azure|aws> <1 for deploy AG in VM | 2 for deploy AG inside k8s cluster> <true will enable Dynatrace | false wont enable Dynatrace>"
    exit 1
fi

case "$1" in
"gcp")
    echo ""
    echo "Google Cloud"
    echo ""
    NUMBER=$(shuf -i 200000-300000 -n 1)
    export PROJECT_NAME=project-demo
    read -p 'gcp Project ID ('${PROJECT_NAME}-${NUMBER}'): ' PROJECT_ID
    if [[ $PROJECT_ID == "" ]]; then
        export PROJECT_ID=${PROJECT_NAME}-${NUMBER}
    else
        export PROJECT_ID=$PROJECT_ID
    fi
    read -p 'gcp k8s zone (us-central1-a): ' ZONEK8SCL
    if [[ $ZONEK8SCL == "" ]]; then
        export ZONEK8SCL=us-central1-a
    else
        export ZONEK8SCL=$ZONEK8SCL
    fi
    export CLOUD_PROVIDER=gcp
    ;;
"azure")
    echo ""
    echo "Azure"
    echo ""
    CURRENT_SUBSCRIPTION=$(az account list --query "[?isDefault].id" -o tsv)
    read -p 'Azure Subscription ID('$CURRENT_SUBSCRIPTION'): ' SUBSCRIPTION_ID
    if [[ $SUBSCRIPTION_ID == "" ]]; then
        export SUBSCRIPTION_ID=$CURRENT_SUBSCRIPTION
    else
        export SUBSCRIPTION_ID=$SUBSCRIPTION_ID
    fi
    read -p 'Azure Resource Group(JRK8SDEMORG01): ' RG_NAME
    if [[ $RG_NAME == "" ]]; then
        export RG_NAME=JRK8SDEMORG01
    else
        export RG_NAME=$RG_NAME
    fi
    read -p 'azure k8s region (eastus): ' REGIONK8SCL
    if [[ $REGIONK8SCL == "" ]]; then
        export REGIONK8SCL=eastus
    else
        export REGIONK8SCL=$REGIONK8SCL
    fi
    read -p 'azure VM region (westus2): ' REGIONVM
    if [[ $REGIONVM == "" ]]; then
        export REGIONVM=westus2
    else
        export REGIONVM=$REGIONVM
    fi
    export CLOUD_PROVIDER=azure
    ;;
"aws")
    echo ""
    echo "aws"
    echo ""
    read -p 'aws k8s region (us-east-1): ' REGIONK8SCL
    if [[ $REGIONK8SCL == "" ]]; then
        export REGIONK8SCL=us-east-1
    else
        export REGIONK8SCL=$REGIONK8SCL
    fi
    export CLOUD_PROVIDER=azure
    ;;
*)
    echo "No supported Cloud Provider (gcp or azure) detected."
    exit 1
    ;;
esac

case "$2" in
"1")
    read -p 'gcp VM zone (us-east1-b): ' ZONEVM
    if [[ $ZONEVM == "" ]]; then
        export ZONEVM=us-east1-b
    else
        export ZONEVM=$ZONEVM
    fi
    echo ""
    echo "Dynatrace ActiveGate server will be created."
    echo ""
    export 
    export AG_TYPE=1
    ;;
"2")
    echo ""
    echo "Dynatrace Activegate server won't be created."
    echo ""
    export AG_TYPE=2
    ;;
*)
    echo "No supported AG deployment type (1|2) detected."
    exit 1
    ;;
esac

case "$3" in
true)
    export DT_TYPE=1
    echo "Dynatrace will be deployed on this cluster."
    export CREDS=./1-credentials/creds.json

    if [ -f "$CREDS" ]; then
        echo "The $CREDS file exists."
    else
        echo "The $CREDS file does not exists. Executing the defineDTcredentials.sh script..."
        cd ./1-credentials
        ./defineDTCredentials.sh
        cd ..
    fi

    export DT_TENANTID=$(cat ./1-credentials/creds.json | jq -r '.dynatraceTenantID')
    export DT_ENVIRONMENTID=$(cat ./1-credentials/creds.json | jq -r '.dynatraceEnvironmentID')
    export DT_API_TOKEN=$(cat ./1-credentials/creds.json | jq -r '.dynatraceApiToken')
    #export AG=$(cat ../1-credentials/creds.json | jq -r '.dynatracactiveGate')
    ;;
false)
    export DT_TYPE=0
    echo "Dynatrace won't be deployed on this cluster."
    ;;
*)
    echo "No supported Dynatrace deployment (1|0) detected."
    exit 1
    ;;
esac

case $CLOUD_PROVIDER in
gcp)
    cd ./2-cloudServices/gcp
    ./createServices.sh
    cd ../..
    ;;
azure)
    cd ./2-cloudServices/azure
    ./createServices.sh
    cd ../..
    ;;
aws)
    cd ./2-cloudServices/aws
    ./createServices.sh
    cd ../..
    ;;
*)
    echo "No supported Cloud Provider (gcp or AKS) detected."
    exit 1
    ;;
esac

#Dynatrace setup...
case $DT_TYPE in
1)
    #install Dynatrace Operator on k8s cluster...
    cd ./3-dynatrace/dynatraceOperator/
    ./installDynatraceOperator.sh
    cd ../..

    #Connect kubernetes public API with Dynatrace...
    if [[ $AG_TYPE == "1" ]];then

        cd ./3-dynatrace/connectK8sDynatrace
        ./k8sClusterToDynatrace.sh
        cd ../..

    fi
    ;;
esac

#install sockshop app on k8s cluster...

cd ./4-app/sockShop/
./installSockShopDev.sh
./installSockShopStaging.sh
./installSockShopProduction.sh
cd ../..