#!/bin/bash

echo ""
echo "-------------------------------"
echo "Creating SockShop dev namespace"
echo "-------------------------------"
echo ""
kubectl create -f ../../manifests/sockShop/dev/sockshop-namespace.yaml
echo ""
echo "------------------------------------"
echo "Applying dev user-db backend-service"
echo "------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/dev/backend-services/user-db/user-db-persistentvolume.yaml
kubectl apply -f ../../manifests/sockShop/dev/backend-services/user-db/user-db-deployment.yaml
kubectl apply -f ../../manifests/sockShop/dev/backend-services/user-db/user-db-service.yaml
echo ""
echo "----------------------------------------------"
echo "Applying dev shipping rabbitmq backend-service"
echo "----------------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/dev/backend-services/shipping-rabbitmq/shipping-rabbitmq-deployment.yaml
kubectl apply -f ../../manifests/sockShop/dev/backend-services/shipping-rabbitmq/shipping-rabbitmq-service.yaml
echo ""
echo "-------------------------------------"
echo "Applying dev carts-db backend-service"
echo "-------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/dev/backend-services/carts-db/carts-db-persistentvolume.yaml
kubectl apply -f ../../manifests/sockShop/dev/backend-services/carts-db/carts-db-deployment.yaml
kubectl apply -f ../../manifests/sockShop/dev/backend-services/carts-db/carts-db-service.yaml
echo ""
echo "-----------------------------------------"
echo "Applying dev catalogue-db backend-service"
echo "-----------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/dev/backend-services/catalogue-db/catalogue-db-deployment.yaml
kubectl apply -f ../../manifests/sockShop/dev/backend-services/catalogue-db/catalogue-db-service.yaml
echo ""
echo "--------------------------------------"
echo "Applying dev orders-db backend-service"
echo "--------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/dev/backend-services/orders-db/orders-db-persistentvolume.yaml
kubectl apply -f ../../manifests/sockShop/dev/backend-services/orders-db/orders-db-deployment.yaml
kubectl apply -f ../../manifests/sockShop/dev/backend-services/orders-db/orders-db-service.yaml
echo ""
echo "--------------------------"
echo "Applying dev core-services"
echo "--------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/dev/core-services/
echo ""
echo "------------------------------"
echo "Applying dev frontend-services"
echo "------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/dev/frontend-services/front-end.yaml
echo ""
echo "------------------------"
echo "Creating dev rolebinding"
echo "------------------------"
echo ""
kubectl -n sockshop-dev create rolebinding default-view --clusterrole=view --serviceaccount=sockshop-dev:default