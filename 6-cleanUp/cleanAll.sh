#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo ""
    echo "No supported Cloud Provider (gcp or azure or aws) detected."
    echo ""
    exit 1
fi

case "$1" in
"gcp")
    echo ""
    echo "Google Cloud"
    export CLOUD_PROVIDER=gcp
    ;;
"azure")
    echo ""
    echo "Azure"
    export CLOUD_PROVIDER=azure
    ;;
*)
    echo "No supported Cloud Provider (gcp or azure or aws) detected."
    exit 1
    ;;
esac

export CLUSTER_NAME=$(cat ../2-cloudServices/$CLOUD_PROVIDER/servicesInfo.json | jq -r '.k8sClusterName')
export AGTYPE=$(cat ../2-cloudServices/$CLOUD_PROVIDER/servicesInfo.json | jq -r '.agType')
export DYNATRACEDEPLOY=$(cat ../2-cloudServices/$CLOUD_PROVIDER/servicesInfo.json | jq -r '.dynatraceDeploy')

if [[ $DYNATRACEDEPLOY == true ]];then
    export DT_TENANTID=$(cat ../1-credentials/creds.json | jq -r '.dynatraceTenantID')
    export DT_ENVIRONMENTID=$(cat ../1-credentials/creds.json | jq -r '.dynatraceEnvironmentID')
    export DT_API_TOKEN=$(cat ../1-credentials/creds.json | jq -r '.dynatraceApiToken')
    export DT_K8S_ID=$(cat ../3-dynatrace/connectK8sDynatrace/dynatracek8sinfo.json | jq -r '.dynatrace_k8s_objectid')

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

    echo ""
    echo "-------------------------------------------------------"
    echo "Cheking Dynatrace k8s integration for '"$CLUSTER_NAME"'"
    echo "-------------------------------------------------------"
    echo ""

    if [[ $AGTYPE == "internal" ]]; then

        DT_K8S_LIST=$(curl -X GET "$DYNATRACE_BASE_URL/api/v2/settings/objects?schemaIds=builtin%3Acloud.kubernetes&fields=objectId%2Cvalue" -H "accept: application/json; charset=utf-8" -H "Authorization: Api-Token $DT_API_TOKEN")

        for ((j = 0; j <= $(echo $DT_K8S_LIST | jq -r '.totalCount') - 1; j++)); do

            DT_K8S_NAME=$(echo $DT_K8S_LIST | jq -r '.items['$j'].value.label')
            DT_K8S_ID=$(echo $DT_K8S_LIST | jq -r '.items['$j'].objectId')
            
            if [[ $CLUSTER_NAME == $DT_K8S_NAME ]]; then

                echo "Deleting Dynatrace k8s integracion for '"$CLUSTER_NAME"'"

                curl -X 'DELETE' "$DYNATRACE_BASE_URL/api/v2/settings/objects/$DT_K8S_ID" -H "accept: */*" -H "Authorization: Api-Token $DT_API_TOKEN"

            fi

        done

    fi

    if [[ $AGTYPE == "external" ]]; then

        echo "Deleting Dynatrace k8s integracion for '"$CLUSTER_NAME"'..."

        curl -X "DELETE" "$DYNATRACE_BASE_URL/api/v2/settings/objects/$DT_K8S_ID" -H "accept: */*" -H "Authorization: Api-Token $DT_API_TOKEN"

        INFO=$(
        cat <<EOF
        {
            "dynatrace_k8s_objectid": ""
        }
EOF
)

    FILE=../3-dynatrace/connectK8sDynatrace/dynatracek8sinfo.json
    rm $FILE 2>/dev/null

    echo $INFO | jq -r '.' >>$FILE

    fi
    echo ""
    echo "------------------------------------------------------------------------------"
    echo "Deleting Dynatrace CRDs and namespace on Cluster '"$CLUSTER_NAME"'"
    echo "------------------------------------------------------------------------------"
    echo ""
    kubectl delete crd dynakubes.dynatrace.com
    kubectl delete namespace dynatrace

fi

echo ""
echo "---------------------------------------------------------"
echo "Deleting application sockshop running on '"$CLUSTER_NAME"'"
echo "---------------------------------------------------------"

./cleanApp.sh

echo ""
echo "-----------------------------------------"
echo "Deleting '"$CLOUD_PROVIDER"' cloud services"
echo "-----------------------------------------"
echo ""
if [ $CLOUD_PROVIDER == "gcp" ]; then
    cd gcp
    ./deleteServices.sh
    cd ..
fi

if [ $CLOUD_PROVIDER == "azure" ]; then
    cd azure
    ./deleteServices.sh
    cd ..
fi