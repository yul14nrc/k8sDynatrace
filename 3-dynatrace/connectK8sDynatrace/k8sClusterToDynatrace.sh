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

echo ""
echo "Verifying dynatrace namespace..."
echo ""

ns=$(kubectl get namespace dynatrace --no-headers --output=go-template={{.metadata.name}} --kubeconfig ~/.kube/config 2>/dev/null)
if [ -z "${ns}" ]; then
    echo "Namespace dynatrace not found"
    echo ""
    echo "Creating namespace dynatrace:"
    echo ""
    kubectl create namespace dynatrace --kubeconfig ~/.kube/config
else
    echo "Namespace dynatrace exists"
    echo ""
    echo "Using namespace dynatrace"
fi

echo ""
echo "Creating monitoring service account:"
echo ""
kubectl apply -f ./kubernetes-monitoring-service-account.yaml --kubeconfig ~/.kube/config
echo ""

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

DYNATRACE_API_TOKEN="$DT_API_TOKEN"
DYNATRACE_API_URL="$DYNATRACE_BASE_URL/api/config/v1/kubernetes/credentials"

API_ENDPOINT_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' --kubeconfig ~/.kube/config)
BEARER_TOKEN=$(kubectl get secret $(kubectl get sa dynatrace-monitoring -o jsonpath='{.secrets[0].name}' -n dynatrace --kubeconfig ~/.kube/config) -o jsonpath='{.data.token}' -n dynatrace --kubeconfig ~/.kube/config | base64 --decode)

echo "================================================================="
echo "Dynatrace Kubernetes configuration:"
echo ""
echo "DYNATRACE_BASE_URL         = $DYNATRACE_BASE_URL"
echo "DYNATRACE_API_URL          = $DYNATRACE_API_URL"
echo "DYNATRACE_API_TOKEN        = $DYNATRACE_API_TOKEN"
echo "================================================================="
echo ""
POST_DATA=$(
    cat <<EOF
    {
        "label": "sockshop-k8s-cl",
        "endpointUrl": "$API_ENDPOINT_URL",
        "authToken": "$BEARER_TOKEN",
        "eventsFieldSelectors": [
            {
                "label": "Node warning events",
                "fieldSelector": "involvedObject.kind=Node,type=Warning",
                "active": true
            },
            {
                "label": "Sockshop prod warning events",
                "fieldSelector": "involvedObject.namespace=sockshop-production,type=Warning",
                "active": true
            }
        ],
        "active": true,
        "eventsIntegrationEnabled": true,
        "workloadIntegrationEnabled": true,
        "certificateCheckEnabled": false,
        "hostnameVerificationEnabled": true,
        "davisEventsIntegrationEnabled": true
    }
EOF
)
echo $POST_DATA
echo ""
echo "Result: "
echo ""
CONNECT_K8S_DYNATRACE=$(curl -X POST "$DYNATRACE_API_URL" -H "Content-type: application/json" -H "Authorization: Api-Token "$DYNATRACE_API_TOKEN -d "$POST_DATA")

echo $CONNECT_K8S_DYNATRACE

DYNATRACE_K8S_ID=$(echo $CONNECT_K8S_DYNATRACE | jq -r '.id')
DYNATRACE_K8S_NAME=$(echo $CONNECT_K8S_DYNATRACE | jq -r '.name')

INFO=$(
    cat <<EOF
    {
        "dynatrace_k8s_id": "$DYNATRACE_K8S_ID",
        "dynatrace_k8s_name": "$DYNATRACE_K8S_NAME"
    }
EOF
)

FILE=./dynatracek8sinfo.json
rm $FILE 2>/dev/null

echo $INFO | jq -r '.' >>$FILE
