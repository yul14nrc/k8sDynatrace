#!/bin/bash

exec > >(tee -i ./k8sinforesult.log)
exec 2>&1

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
kubectl apply -f ./kubernetes-monitoring-service-account.yaml
echo ""

echo "You have to use the following information in the Dynatrace UI:"
echo ""

echo "Kubernetes API URL:"
echo ""
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
echo ""
echo ""
echo "Bearer token:"
echo ""
kubectl get secret $(kubectl get sa dynatrace-monitoring -o jsonpath='{.secrets[0].name}' -n dynatrace) -o jsonpath='{.data.token}' -n dynatrace | base64 --decode
echo ""
echo ""

API_ENDPOINT_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
API_SERVER_PORT="$(echo $API_ENDPOINT_URL | sed -e "s/https:\/\///"):443"
echo "API Server:"
echo -e "${YLW}${NC}${API_SERVER_PORT}"
echo ""

if [ -d "./certificatek8s" ]; then
    echo "Directory ./certificatek8s exists"
else
    echo "Creating directory ./certificatek8s..."
    mkdir certificatek8s
fi

echo ""
echo "Saving kubernetes certificate..."
echo Q | openssl s_client -connect $API_SERVER_PORT 2>/dev/null | openssl x509 -outform PEM >./certificatek8s/dt_k8s_api.pem
echo ""
cat ./certificatek8s/dt_k8s_api.pem
echo ""
