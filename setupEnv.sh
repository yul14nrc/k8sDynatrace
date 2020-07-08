#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo ""
    echo "No supported Cloud Provider (GCP or azure or AWS) detected."
    echo ""
    exit 1
fi

if [ "$1" == "GCP" ]; then
    echo ""
    echo "Google Cloud"
    echo ""
    export CLOUD_PROVIDER=GCP
else
    echo ""
    echo "No supported Cloud Provider (GCP or azure or AWS) detected."
    echo ""
    exit 1
fi

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
export DT_PAAS_TOKEN=$(cat ./1-credentials/creds.json | jq -r '.dynatracePaaSToken')
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