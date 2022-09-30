#!/bin/bash

#https://github.com/GoogleCloudPlatform/bank-of-anthos

# Deploy Bank of Anthos to production

echo ""
echo "--------------------------------------------"
echo "Creating Bank Of Anthos production namespace"
echo "--------------------------------------------"
echo ""
kubectl create -f ../../manifests/bankOfAnthos/production/bankofanthos-namespace.yaml --kubeconfig ~/.kube/config
echo ""
echo "------------------------------------------------------"
echo "Creating Bank Of Anthos production JWT Key pair secret"
echo "------------------------------------------------------"
echo ""
openssl genrsa -out jwtRS256.key 4096
openssl rsa -in jwtRS256.key -outform PEM -pubout -out jwtRS256.key.pub
kubectl create secret generic jwt-key --from-file=./jwtRS256.key --from-file=./jwtRS256.key.pub -n bankofanthos-production
echo ""
echo "----------------------------------------------"
echo "Applying Bank Of Anthos production db services"
echo "----------------------------------------------"
echo ""
kubectl apply -f ../../manifests/bankOfAnthos/production/db-services/accounts-db.yaml --kubeconfig ~/.kube/config -n bankofanthos-production
kubectl apply -f ../../manifests/bankOfAnthos/production/db-services/ledger-db.yaml --kubeconfig ~/.kube/config -n bankofanthos-production
echo ""
echo "-----------------------------------------------"
echo "Applying Bank Of Anthos production core-service"
echo "-----------------------------------------------"
echo ""
kubectl apply -f ../../manifests/bankOfAnthos/production/core-services/balance-reader.yaml --kubeconfig ~/.kube/config -n bankofanthos-production
kubectl apply -f ../../manifests/bankOfAnthos/production/core-services/config.yaml --kubeconfig ~/.kube/config -n bankofanthos-production
kubectl apply -f ../../manifests/bankOfAnthos/production/core-services/contacts.yaml --kubeconfig ~/.kube/config -n bankofanthos-production
kubectl apply -f ../../manifests/bankOfAnthos/production/core-services/ledger-writer.yaml --kubeconfig ~/.kube/config -n bankofanthos-production
kubectl apply -f ../../manifests/bankOfAnthos/production/core-services/transaction-history.yaml --kubeconfig ~/.kube/config -n bankofanthos-production
kubectl apply -f ../../manifests/bankOfAnthos/production/core-services/user.yaml --kubeconfig ~/.kube/config -n bankofanthos-production
echo ""
echo "----------------------------------------------------"
echo "Applying Bank Of Anthos production frontend-services"
echo "----------------------------------------------------"
echo ""
kubectl apply -f ../../manifests/bankOfAnthos/production/frontend-services/front-end.yaml --kubeconfig ~/.kube/config -n bankofanthos-production
echo ""
echo "-------------------------------------------------"
echo "Applying Bank Of Anthos production load generator"
echo "-------------------------------------------------"
echo ""
kubectl apply -f ../../manifests/bankOfAnthos/production/aditional-services/load-generator.yaml --kubeconfig ~/.kube/config -n bankofanthos-production