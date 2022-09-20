#!/bin/bash

#stop Carts Load Test
#export CARTS_LOADTEST_PID=$(ps -o pid= -C cartsLoadTest.sh)
#kill -9 $CARTS_LOADTEST_PID
#echo "Carts load test PID $CARTS_LOADTEST_PID was stopped"

if [[ $CLOUD_PROVIDER == "GCP" ]]; then
    K8S_TYPE=GKE
fi

if [[ $CLOUD_PROVIDER == "azure" ]]; then
    K8S_TYPE=AKS
fi

echo ""
echo "------------------------------------------------------------------------------"
echo "Deleting CRDs on $K8S_TYPE Cluster '"$CLUSTER_NAME"'"
echo "------------------------------------------------------------------------------"
echo ""
#delete CRDs
kubectl delete crd dynakubes.dynatrace.com
echo ""
echo "---------------------------------------------------------------------"
echo "Removing Cluster Role Bindings on $K8S_TYPE Cluster '"$CLUSTER_NAME"'"
echo "---------------------------------------------------------------------"
echo ""
#remove cluster role bindings
kubectl delete rolebinding default-view -n sockshop-dev
kubectl delete rolebinding default-view -n sockshop-staging
kubectl delete rolebinding default-view -n sockshop-production
kubectl delete clusterrolebinding cluster-admin-binding
echo ""
echo "----------------------------------------------------------"
echo "Deleting namespaces on $K8S_TYPE Cluster '"$CLUSTER_NAME"'"
echo "----------------------------------------------------------"
echo ""
#remove namespaces and their objects
kubectl delete namespace sockshop-dev
kubectl delete namespace sockshop-staging
kubectl delete namespace sockshop-production
kubectl delete namespace dynatrace
#kubectl delete ns cicd
#kubectl delete ns tower