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

export TENANTID=$(cat ./1-credentials/creds.json | jq -r '.dynatraceTenantID')
export ENVIRONMENTID=$(cat ./1-credentials/creds.json | jq -r '.dynatraceEnvironmentID')
export API_TOKEN=$(cat ./1-credentials/creds.json | jq -r '.dynatraceApiToken')
export PAAS_TOKEN=$(cat ./1-credentials/creds.json | jq -r '.dynatracePaaSToken')
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