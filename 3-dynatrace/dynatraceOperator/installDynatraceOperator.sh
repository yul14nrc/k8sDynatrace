#!/bin/bash

#export DT_TENANTID=$(cat ../../1-credentials/creds.json | jq -r '.dynatraceTenantID')
#export DT_ENVIRONMENTID=$(cat ../../1-credentials/creds.json | jq -r '.dynatraceEnvironmentID')
#export DT_API_TOKEN=$(cat ../../1-credentials/creds.json | jq -r '.dynatraceApiToken')
#export DT_PAAS_TOKEN=$(cat ../../1-credentials/creds.json | jq -r '.dynatracePaaSToken')

echo ""
echo "Verifying dynatrace namespace..."
echo ""

ns=$(kubectl get namespace dynatrace --no-headers --output=go-template={{.metadata.name}} 2>/dev/null)
if [ -z "${ns}" ]; then
  echo "Namespace dynatrace not found"
  echo ""
  echo "Creating namespace dynatrace"
  echo ""
  kubectl create namespace dynatrace
else
  echo "Namespace dynatrace exists"
  echo ""
  echo "Using namespace dynatrace"
fi

LATEST_RELEASE=$(curl -s https://api.github.com/repos/dynatrace/dynatrace-oneagent-operator/releases/latest | grep tag_name | cut -d '"' -f 4)
#LATEST_RELEASE=v0.3.1
kubectl create -f https://github.com/Dynatrace/dynatrace-oneagent-operator/releases/download/$LATEST_RELEASE/kubernetes.yaml

kubectl -n dynatrace create secret generic oneagent --from-literal="apiToken="$DT_API_TOKEN --from-literal="paasToken="$DT_PAAS_TOKEN

if [[ -f "cr.yaml" ]]; then
  rm -f cr.yaml
  echo "Removed cr.yaml"
fi

curl -o cr.yaml https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/$LATEST_RELEASE/deploy/cr.yaml

case $DT_ENVIRONMENTID in
'')
  echo "SaaS Deplyoment"
  sed -i 's/apiUrl: https:\/\/ENVIRONMENTID.live.dynatrace.com\/api/apiUrl: https:\/\/'$DT_TENANTID'.live.dynatrace.com\/api/' cr.yaml
  ;;
*)
  echo "Managed Deployment"
  sed -i 's/apiUrl: https:\/\/ENVIRONMENTID.live.dynatrace.com\/api/apiUrl: https:\/\/'$DT_TENANTID'.dynatrace-managed.com\/e\/'$DT_ENVIRONMENTID'\/api/' cr.yaml
  ;;
?)
  usage
  ;;
esac

kubectl create -f cr.yaml
