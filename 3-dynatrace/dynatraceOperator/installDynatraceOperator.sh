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
  echo "Creating namespace dynatrace"
  echo ""
  kubectl create namespace dynatrace --kubeconfig ~/.kube/config
else
  echo "Namespace dynatrace exists"
  echo ""
  echo "Using namespace dynatrace"
fi

DT_OPERATOR_LAST_VERSION="v1.0.1"

kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/$DT_OPERATOR_LAST_VERSION/kubernetes.yaml --kubeconfig ~/.kube/config

kubectl -n dynatrace wait pod --for=condition=ready --selector=app.kubernetes.io/name=dynatrace-operator,app.kubernetes.io/component=webhook --timeout=300s --kubeconfig ~/.kube/config

kubectl -n dynatrace create secret generic dynakube --from-literal="apiToken=$DT_API_TOKEN" --kubeconfig ~/.kube/config

if [[ $CLOUD_PROVIDER == "gcp" ]]; then
  sed -i '0,/# env: \[\]/s/# env: \[\]/env:\n      - name: ONEAGENT_ENABLE_VOLUME_STORAGE\n        value: "true"/g' cr.yaml crAG.yaml
fi

#curl -o cr.yaml https://raw.githubusercontent.com/Dynatrace/dynatrace-operator/master/config/samples/cr.yaml

if [[ $AG_TYPE == "1" ]];then

  case $DT_ENVIRONMENTID in
  '')
    echo "SaaS Deployment"
    sed -i 's/apiUrl: https:\/\/ENVIRONMENTID.live.dynatrace.com\/api/apiUrl: https:\/\/'$DT_TENANTID'.live.dynatrace.com\/api/' cr.yaml
    sed -i 's/CLUSTER/'$CLUSTER_NAME'/' cr.yaml
    ;;
  *)
    echo "Managed Deployment"
    sed -i 's/apiUrl: https:\/\/ENVIRONMENTID.live.dynatrace.com\/api/apiUrl: https:\/\/'$DT_TENANTID'.dynatrace-managed.com\/e\/'$DT_ENVIRONMENTID'\/api/' cr.yaml
    sed -i 's/CLUSTER/'$CLUSTER_NAME'/' cr.yaml
    ;;
  ?)
    usage
    ;;
  esac

  kubectl apply -f cr.yaml --kubeconfig ~/.kube/config

else

  case $DT_ENVIRONMENTID in
  '')
    echo "SaaS Deployment"
    sed -i 's/apiUrl: https:\/\/ENVIRONMENTID.live.dynatrace.com\/api/apiUrl: https:\/\/'$DT_TENANTID'.live.dynatrace.com\/api/' crAG.yaml
    sed -i 's/CLUSTER/'$CLUSTER_NAME'/' crAG.yaml
    ;;
  *)
    echo "Managed Deployment"
    sed -i 's/apiUrl: https:\/\/ENVIRONMENTID.live.dynatrace.com\/api/apiUrl: https:\/\/'$DT_TENANTID'.dynatrace-managed.com\/e\/'$DT_ENVIRONMENTID'\/api/' crAG.yaml
    sed -i 's/CLUSTER/'$CLUSTER_NAME'/' crAG.yaml
    ;;
  ?)
    usage
    ;;
  esac

  kubectl apply -f crAG.yaml --kubeconfig ~/.kube/config

fi