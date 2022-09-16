#!/bin/bash

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