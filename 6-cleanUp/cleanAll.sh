#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo ""
    echo "No supported Cloud Provider (GCP or azure or AWS) detected."
    echo ""
    exit 1
fi

export DT_TENANTID=$(cat ../1-credentials/creds.json | jq -r '.dynatraceTenantID')
export DT_ENVIRONMENTID=$(cat ../1-credentials/creds.json | jq -r '.dynatraceEnvironmentID')
export DT_API_TOKEN=$(cat ../1-credentials/creds.json | jq -r '.dynatraceApiToken')
export DT_K8S_ID=$(cat ../3-dynatrace/connectK8sDynatrace/dynatracek8sinfo.json | jq -r '.dynatrace_k8s_id')

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

case "$1" in
"GCP")
    echo ""
    echo "Google Cloud"
    export CLOUD_PROVIDER=GCP
    ;;
"azure")
    echo ""
    echo "Azure"
    export CLOUD_PROVIDER=azure
    ;;
*)
    echo "No supported Cloud Provider (GCP or azure) detected."
    exit 1
    ;;
esac

./cleanApp.sh

if [ $CLOUD_PROVIDER == "GCP" ]; then
    cd GCP
    ./deleteServices.sh
    cd ..
fi

if [ $CLOUD_PROVIDER == "azure" ]; then
    cd azure
    ./deleteServices.sh
    cd ..
fi

curl -X DELETE "$DYNATRACE_BASE_URL/api/config/v1/kubernetes/credentials/$DT_K8S_ID" -H "accept: */*" -H "Authorization: Api-Token $DT_API_TOKEN"
