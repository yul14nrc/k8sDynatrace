#!/bin/bash
echo ""
echo "---------------------------------------------------------------------"
echo "Removing Cluster Role Bindings on cluster '"$CLUSTER_NAME"'"
echo "---------------------------------------------------------------------"
echo ""
#remove cluster role bindings
kubectl delete rolebinding default-view -n sockshop-dev
kubectl delete rolebinding default-view -n sockshop-staging
kubectl delete rolebinding default-view -n sockshop-production
kubectl delete clusterrolebinding cluster-admin-binding
echo ""
echo "----------------------------------------------------------"
echo "Deleting namespaces on cluster '"$CLUSTER_NAME"'"
echo "----------------------------------------------------------"
echo ""
#remove namespaces and their objects
kubectl delete namespace sockshop-dev
kubectl delete namespace sockshop-staging
kubectl delete namespace sockshop-production