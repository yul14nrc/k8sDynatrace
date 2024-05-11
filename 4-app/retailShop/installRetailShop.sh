#!/bin/bash
echo ""
echo "-------------------------------"
echo "Creating retail namespace"
echo "-------------------------------"
echo ""
kubectl create namespace retail --kubeconfig ~/.kube/config
echo ""
echo "------------------------------------"
echo "Deploying manifests"
echo "------------------------------------"
echo ""
kubectl apply -f https://raw.githubusercontent.com/aws-containers/retail-store-sample-app/main/dist/kubernetes/deploy.yaml -n retail --kubeconfig ~/.kube/config
echo ""
echo "-------------------------------------"
echo "Waiting to application status running"
echo "-------------------------------------"
kubectl wait --for=condition=available deployments -n retail --kubeconfig ~/.kube/config