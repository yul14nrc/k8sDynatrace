#!/bin/bash

#stop Carts Load Test
#export CARTS_LOADTEST_PID=$(ps -o pid= -C cartsLoadTest.sh)
#kill -9 $CARTS_LOADTEST_PID
#echo "Carts load test PID $CARTS_LOADTEST_PID was stopped"

echo ""
echo "------------------------------------------------------------------------"
echo "Deleting POD security policies and CRDs on GKE Cluster '"$CLUSTER_NAME"'"
echo "------------------------------------------------------------------------"
echo ""
#delete pod security policies and CRDs
kubectl delete podsecuritypolicy dynatrace-oneagent
kubectl delete podsecuritypolicy dynatrace-oneagent-operator
kubectl delete crd oneagents.dynatrace.com
echo ""
echo "---------------------------------------------------------------"
echo "Removing Cluster Role Bindings on GKE Cluster '"$CLUSTER_NAME"'"
echo "---------------------------------------------------------------"
echo ""
#remove cluster role bindings
kubectl delete rolebinding default-view -n sockshop-dev
kubectl delete rolebinding default-view -n sockshop-staging
kubectl delete rolebinding default-view -n sockshop-production
kubectl delete clusterrolebinding cluster-admin-binding
echo ""
echo "---------------------------------------------------------------"
echo "Deleting namespaces on GKE Cluster '"$CLUSTER_NAME"'"
echo "---------------------------------------------------------------"
echo ""
#remove namespaces and their objects
kubectl delete namespace sockshop-dev
kubectl delete namespace sockshop-staging
kubectl delete namespace sockshop-production
kubectl delete namespace dynatrace
#kubectl delete ns cicd
#kubectl delete ns tower