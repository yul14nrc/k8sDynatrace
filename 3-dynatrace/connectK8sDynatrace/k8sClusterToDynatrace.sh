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

ns=$(kubectl get namespace dynatrace --no-headers --output=go-template={{.metadata.name}} 2>/dev/null)
if [ -z "${ns}" ]; then
    echo "Namespace dynatrace not found"
    echo ""
    echo "Creating namespace dynatrace:"
    echo ""
    kubectl create namespace dynatrace
else
    echo "Namespace dynatrace exists"
    echo ""
    echo "Using namespace dynatrace"
fi

echo ""
echo "Creating monitoring service account:"
echo ""
if [[ -f "kubernetes-monitoring-service-account.yaml" ]]; then
    rm -f kubernetes-monitoring-service-account.yaml
fi
curl -o kubernetes-monitoring-service-account.yaml https://www.dynatrace.com/support/help/codefiles/kubernetes/kubernetes-monitoring-service-account.yaml
echo ""
kubectl apply -f ./kubernetes-monitoring-service-account.yaml
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

API_ENDPOINT_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
BEARER_TOKEN=$(kubectl get secret $(kubectl get sa dynatrace-monitoring -o jsonpath='{.secrets[0].name}' -n dynatrace) -o jsonpath='{.data.token}' -n dynatrace | base64 --decode)

echo "================================================================="
echo "Dynatrace Kubernetes configuration:"
echo ""
echo "DYNATRACE_BASE_URL         = $DYNATRACE_BASE_URL"
echo "DYNATRACE_API_URL          = $DYNATRACE_API_URL"
echo "DYNATRACE_API_TOKEN        = $DYNATRACE_API_TOKEN"
echo "================================================================="
echo ""
POST_DATA=$(cat <<EOF
    {
        "label": "sockshop-k8s-cl",
        "endpointUrl": "$API_ENDPOINT_URL",
        "authToken": "$BEARER_TOKEN",
        "eventsFieldSelectors": [
            {
                "label": "Node events",
                "fieldSelector": "involvedObject.kind=Node",
                "active": true
            }
        ],
        "active": true,
        "eventsIntegrationEnabled": true,
        "workloadIntegrationEnabled": true,
        "certificateCheckEnabled": true
    }
EOF
)
echo $POST_DATA
echo ""
echo "Result: "
echo ""
curl -X POST "$DYNATRACE_API_URL" -H "Content-type: application/json" -H "Authorization: Api-Token "$DYNATRACE_API_TOKEN -d "$POST_DATA"
