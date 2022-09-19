#!/bin/bash

export CLUSTER_NAME=k8s-demo-cl
export K8S_VERSION="1.22"
export VM_NAME=dtactivegate

if [ "$#" -ne 2 ]; then
    echo ""
    echo "No supported Cloud Provider (GCP or azure or AWS) detected or AG deployment type."
    echo ""
    echo "usage: setupEnv.sh <GCP|azure|AWS> <1 for deploy AG in VM|2 for deploy AG inside k8s cluster>"
    exit 1
fi

case "$1" in
"GCP")
    echo ""
    echo "Google Cloud"
    echo ""
    NUMBER=$(shuf -i 200000-300000 -n 1)
    export PROJECT_NAME=project-demo
    read -p 'GCP Project ID ('${PROJECT_NAME}-${NUMBER}'): ' PROJECT_ID
    if [[ $PROJECT_ID == "" ]]; then
        export PROJECT_ID=${PROJECT_NAME}-${NUMBER}
    else
        export PROJECT_ID=$PROJECT_ID
    fi
    read -p 'GCP k8s zone (us-central1-a): ' ZONEK8SCL
    if [[ $ZONEK8SCL == "" ]]; then
        export ZONEK8SCL=us-central1-a
    else
        export ZONEK8SCL=$ZONEK8SCL
    fi
    read -p 'GCP VM zone (us-east1-b): ' ZONEVM
    if [[ $ZONEVM == "" ]]; then
        export ZONEVM=us-east1-b
    else
        export ZONEVM=$ZONEVM
    fi
    export CLOUD_PROVIDER=GCP
    ;;
"azure")
    echo ""
    echo "Azure"
    echo ""
    export CLOUD_PROVIDER=azure
    ;;
*)
    echo "No supported Cloud Provider (GCP or azure) detected."
    exit 1
    ;;
esac

case "$2" in
"1")
    echo ""
    echo "AG will be deployed in a VM."
    echo ""
    export AG_TYPE=1
    ;;
"2")
    echo ""
    echo "AG will be deployed as a POD inside k8s cluster."
    echo ""
    export AG_TYPE=2
    ;;
*)
    echo "No supported AG deployment type (1|2) detected."
    exit 1
    ;;
esac

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

echo ""

case $CLOUD_PROVIDER in
GCP)
    cd ./2-cloudServices/GCP
    ./createServices.sh
    cd ../..
    ;;
azure)
    deployAKS
    ;;
*)
    echo "No supported Cloud Provider (GCP or AKS) detected."
    exit 1
    ;;
esac

#install Dynatrace Operator on k8s cluster...

cd ./3-dynatrace/dynatraceOperator/
./installDynatraceOperator.sh
cd ../..

#install sockshop app on k8s cluster...

cd ./4-app/sockShop/
./installSockShopDev.sh
./installSockShopStaging.sh
./installSockShopProduction.sh
cd ../..

#connect k8s cluster to dynatrace

if [[ $AG_TYPE == "1" ]];then

    cd ./3-dynatrace/connectK8sDynatrace
    ./k8sClusterToDynatrace.sh
    cd ../..

fi