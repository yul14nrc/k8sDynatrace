#!/bin/bash

# Deploy SockShop to production

echo ""
echo "--------------------------------"
echo "Creating SockShop production namespace"
echo "--------------------------------"
echo ""
kubectl create -f ../../manifests/sockShop/production/sockshop-namespace.yaml --kubeconfig ~/.kube/config
echo ""
echo "------------------------------------"
echo "Applying production userdb backend-service"
echo "------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/production/backend-services/user-db/user-db-persistentvolume.yaml --kubeconfig ~/.kube/config
kubectl apply -f ../../manifests/sockShop/production/backend-services/user-db/user-db-deployment.yaml --kubeconfig ~/.kube/config
kubectl apply -f ../../manifests/sockShop/production/backend-services/user-db/user-db-service.yaml --kubeconfig ~/.kube/config
echo ""
echo "-----------------------------------------------"
echo "Applying production shipping rabbitmq backend-service"
echo "-----------------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/production/backend-services/shipping-rabbitmq/shipping-rabbitmq-deployment.yaml --kubeconfig ~/.kube/config
kubectl apply -f ../../manifests/sockShop/production/backend-services/shipping-rabbitmq/shipping-rabbitmq-service.yaml --kubeconfig ~/.kube/config
echo ""
echo "--------------------------------------"
echo "Applying production carts-db backend-service"
echo "--------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/production/backend-services/carts-db/carts-db-persistentvolume.yaml --kubeconfig ~/.kube/config
kubectl apply -f ../../manifests/sockShop/production/backend-services/carts-db/carts-db-deployment.yaml --kubeconfig ~/.kube/config
kubectl apply -f ../../manifests/sockShop/production/backend-services/carts-db/carts-db-service.yaml --kubeconfig ~/.kube/config
echo ""
echo "------------------------------------------"
echo "Applying production catalogue-db backend-service"
echo "------------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/production/backend-services/catalogue-db/catalogue-db-deployment.yaml --kubeconfig ~/.kube/config
kubectl apply -f ../../manifests/sockShop/production/backend-services/catalogue-db/catalogue-db-service.yaml --kubeconfig ~/.kube/config
echo ""
echo "--------------------------------------"
echo "Applying production orders-db backend-service"
echo "--------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/production/backend-services/orders-db/orders-db-persistentvolume.yaml --kubeconfig ~/.kube/config
kubectl apply -f ../../manifests/sockShop/production/backend-services/orders-db/orders-db-deployment.yaml --kubeconfig ~/.kube/config
kubectl apply -f ../../manifests/sockShop/production/backend-services/orders-db/orders-db-service.yaml --kubeconfig ~/.kube/config
echo ""
echo "--------------------------"
echo "Applying production core-services"
echo "--------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/production/core-services/ --kubeconfig ~/.kube/config
echo ""
echo "------------------------------"
echo "Applying production frontend-services"
echo "------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/production/frontend-services/front-end.yaml --kubeconfig ~/.kube/config
echo ""
echo "------------------------"
echo "Creating production rolebinding"
echo "------------------------"
echo ""
kubectl -n sockshop-production create rolebinding default-view --clusterrole=view --serviceaccount=sockshop-production:default --kubeconfig ~/.kube/config