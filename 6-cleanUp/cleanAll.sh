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
    export CLUSTER_NAME=$(cat ../2-cloudServices/GCP/servicesInfo.json | jq -r '.k8sClusterName')
    export AGTYPE=$(cat ../2-cloudServices/GCP/servicesInfo.json | jq -r '.agType')
    ;;
"azure")
    echo ""
    echo "Azure"
    export CLOUD_PROVIDER=azure
    export CLUSTER_NAME=$(cat ../2-cloudServices/azure/servicesInfo.json | jq -r '.k8sClusterName')
    export AGTYPE=$(cat ../2-cloudServices/azure/servicesInfo.json | jq -r '.agType')
    ;;
*)
    echo "No supported Cloud Provider (GCP or azure) detected."
    exit 1
    ;;
esac

echo ""
echo "-------------------------------------------------------"
echo "Cheking Dynatrace k8s integration for '"$CLUSTER_NAME"'"
echo "-------------------------------------------------------"
echo ""

if [[ $AGTYPE == "internal" ]]; then

    DT_K8S_LIST=$(curl -X GET "$DYNATRACE_BASE_URL/api/config/v1/kubernetes/credentials" -H "accept: application/json; charset=utf-8" -H "Authorization: Api-Token $DT_API_TOKEN")

    for ((j = 0; j <= $(echo $DT_K8S_LIST | jq -r '.values | length') - 1; j++)); do

        DT_K8S_NAME=$(echo $DT_K8S_LIST | jq -r '.values['$j'].name')
        DT_K8S_ID=$(echo $DT_K8S_LIST | jq -r '.values['$j'].id')
        
        if [[ $CLUSTER_NAME == $DT_K8S_NAME ]]; then

            echo "Deleting Dynatrace k8s integracion for '"$CLUSTER_NAME"'"

            curl -X DELETE "$DYNATRACE_BASE_URL/api/config/v1/kubernetes/credentials/$DT_K8S_ID" -H "accept: */*" -H "Authorization: Api-Token $DT_API_TOKEN"

        fi

    done

fi

if [[ $AGTYPE == "external" ]]; then

    echo "Deleting Dynatrace k8s integracion for '"$CLUSTER_NAME"'"
    curl -X DELETE "$DYNATRACE_BASE_URL/api/config/v1/kubernetes/credentials/$DT_K8S_ID" -H "accept: */*" -H "Authorization: Api-Token $DT_API_TOKEN"

    INFO=$(
    cat <<EOF
    {
        "dynatrace_k8s_id": "",
        "dynatrace_k8s_name": ""
    }
EOF
)

    FILE=../3-dynatrace/connectK8sDynatrace/dynatracek8sinfo.json
    rm $FILE 2>/dev/null

    echo $INFO | jq -r '.' >>$FILE

fi

echo ""
echo "---------------------------------------------------------"
echo "Deleting application sockshop running on '"$CLUSTER_NAME"'"
echo "---------------------------------------------------------"
echo ""

./cleanApp.sh

echo ""
echo "-----------------------------------------"
echo "Deleting "$CLOUD_PROVIDER" cloud services"
echo "-----------------------------------------"
echo ""
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