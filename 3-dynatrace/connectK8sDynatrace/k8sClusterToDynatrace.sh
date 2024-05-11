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
fi

echo ""
echo "Verifying dynatrace namespace..."
echo ""

ns=$(kubectl get namespace dynatrace --no-headers --output=go-template={{.metadata.name}} --kubeconfig ~/.kube/config 2>/dev/null)
if [ -z "${ns}" ]; then
    echo "Namespace dynatrace not found"
    echo ""
    echo "Creating namespace dynatrace..."
    echo ""
    kubectl create namespace dynatrace --kubeconfig ~/.kube/config
else
    echo "Namespace dynatrace exists"
    echo ""
    echo "Using namespace dynatrace"
fi

echo ""
echo "Creating dynatrace-kubernetes-monitoring secret..."
echo ""
kubectl apply -f ./token-secret.yaml -n dynatrace --kubeconfig ~/.kube/config
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
DYNATRACE_API_URL="$DYNATRACE_BASE_URL/api/v2/settings/objects"

API_ENDPOINT_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' --kubeconfig ~/.kube/config)
BEARER_TOKEN=$(kubectl get secret dynatrace-kubernetes-monitoring -o jsonpath='{.data.token}' -n dynatrace --kubeconfig ~/.kube/config | base64 --decode)

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
    [
        {
            "schemaId": "builtin:cloud.kubernetes",
            "value": {
                "enabled": true,
                "label": "$CLUSTER_NAME",
                "clusterIdEnabled": false,
                "endpointUrl": "$API_ENDPOINT_URL",
                "authToken": "$BEARER_TOKEN",
                "certificateCheckEnabled": false,
                "hostnameVerificationEnabled": true
            }
        }
    ]
EOF
)
echo $POST_DATA
echo ""
echo "Result: "
echo ""
CONNECT_K8S_DYNATRACE=$(curl -X POST "$DYNATRACE_API_URL" -H "Content-type: application/json" -H "Authorization: Api-Token "$DYNATRACE_API_TOKEN -d "$POST_DATA")

echo $CONNECT_K8S_DYNATRACE

DYNATRACE_K8S_OBJECTID=$(echo $CONNECT_K8S_DYNATRACE | jq -r '.[0].objectId')

INFO=$(
    cat <<EOF
    {
        "dynatrace_k8s_objectid": "$DYNATRACE_K8S_OBJECTID"
    }
EOF
)

FILE=./dynatracek8sinfo.json
rm $FILE 2>/dev/null

echo $INFO | jq -r '.' >>$FILE
