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
    export DT_PAAS_TOKEN=$(cat ../../1-credentials/creds.json | jq -r '.dynatracePaaSToken')
fi

case $DT_ENVIRONMENTID in
'')
    DYNATRACE_BASE_URL="https://$DT_TENANTID.live.dynatrace.com"
    ;;
*)
    DYNATRACE_BASE_URL="https://$DT_TENANTID.dynatrace-managed.com/e/$DT_ENVIRONMENTID"
    ;;
?)
    usage
    ;;
esac

#Get azure enabled suscription
AZ_SUBSCRIPTION=$(az account list --query '[].id' -o tsv)

#Create an Azure Service Principal
AZ_SERVICE_PRINCIPAL=$(az ad sp create-for-rbac --name Dynatrace --role reader --scopes /subscriptions/$AZ_SUBSCRIPTION)

AZ_APPID=$(echo $AZ_SERVICE_PRINCIPAL | jq -r '.appId')
AZ_TENANT=$(echo $AZ_SERVICE_PRINCIPAL | jq -r '.tenant')
AZ_PASSWORD=$(echo $AZ_SERVICE_PRINCIPAL | jq -r '.password')

DYNATRACE_API_TOKEN="$DT_API_TOKEN"
DYNATRACE_API_URL="$DYNATRACE_BASE_URL/api/config/v1/azure/credentials"

echo "================================================================="
echo "Dynatrace Azure configuration:"
echo ""
echo "DYNATRACE_API_URL          = $DYNATRACE_API_URL"
echo "AZURE APP ID               = $AZ_APPID"
echo "AZURE TENANT               = $AZ_TENANT"
echo "AZURE APP ID PASSWORD      = $AZ_PASSWORD"
echo "================================================================="
echo ""
POST_DATA=$(
    cat <<EOF
    {
        "label": "AzureSubscription",
        "appId": "$AZ_APPID",
        "directoryId": "$AZ_TENANT",
        "key": "$AZ_PASSWORD",
        "active": true,
        "autoTagging": true,
        "monitorOnlyTaggedEntities": false,
        "monitorOnlyTagPairs": []
    }
EOF
)
echo "Body:"
echo ""
echo $POST_DATA
echo ""
echo "Result: "
echo ""
CONNECT_AZURE_DYNATRACE=$(curl -s -X POST "$DYNATRACE_API_URL" -H "Content-type: application/json" -H "Authorization: Api-Token "$DYNATRACE_API_TOKEN -d "$POST_DATA")

echo $CONNECT_AZURE_DYNATRACE

DYNATRACE_AZURE_ID=$(echo $CONNECT_AZURE_DYNATRACE | jq -r '.id')

INFO=$(
    cat <<EOF
    {
        "appId": "$AZ_APPID",
        "password": "$AZ_PASSWORD",
        "tenant": "$AZ_TENANT",
        "dynatrace_azure_id": "$DYNATRACE_AZURE_ID"
    }
EOF
)

FILE=./azureServicePrincipalInfo.json
rm $FILE 2>/dev/null

echo $INFO | jq -r '.' >>$FILE
