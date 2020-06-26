#!/bin/bash

# Deploy SockShop to staging

echo ""
echo "-------------------------------"
echo "Creating SockShop staging namespace"
echo "-------------------------------"
echo ""
kubectl create -f ../../manifests/sockShop/staging/sockshop-namespace.yaml
echo ""
echo "------------------------------------"
echo "Applying staging user-db backend-service"
echo "------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/staging/backend-services/user-db/user-db-persistentvolume.yaml
kubectl apply -f ../../manifests/sockShop/staging/backend-services/user-db/user-db-deployment.yaml
kubectl apply -f ../../manifests/sockShop/staging/backend-services/user-db/user-db-service.yaml
echo ""
echo "----------------------------------------------"
echo "Applying staging shipping rabbitmq backend-service"
echo "----------------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/staging/backend-services/shipping-rabbitmq/shipping-rabbitmq-deployment.yaml
kubectl apply -f ../../manifests/sockShop/staging/backend-services/shipping-rabbitmq/shipping-rabbitmq-service.yaml
echo ""
echo "-------------------------------------"
echo "Applying staging carts-db backend-service"
echo "-------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/staging/backend-services/carts-db/carts-db-persistentvolume.yaml
kubectl apply -f ../../manifests/sockShop/staging/backend-services/carts-db/carts-db-deployment.yaml
kubectl apply -f ../../manifests/sockShop/staging/backend-services/carts-db/carts-db-service.yaml
echo ""
echo "-----------------------------------------"
echo "Applying staging catalogue-db backend-service"
echo "-----------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/staging/backend-services/catalogue-db/catalogue-db-deployment.yaml
kubectl apply -f ../../manifests/sockShop/staging/backend-services/catalogue-db/catalogue-db-service.yaml
echo ""
echo "--------------------------------------"
echo "Applying staging orders-db backend-service"
echo "--------------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/staging/backend-services/orders-db/orders-db-persistentvolume.yaml
kubectl apply -f ../../manifests/sockShop/staging/backend-services/orders-db/orders-db-deployment.yaml
kubectl apply -f ../../manifests/sockShop/staging/backend-services/orders-db/orders-db-service.yaml
echo ""
echo "--------------------------"
echo "Applying staging core-services"
echo "--------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/staging/core-services/
echo ""
echo "------------------------------"
echo "Applying staging frontend-services"
echo "------------------------------"
echo ""
kubectl apply -f ../../manifests/sockShop/staging/frontend-services/front-end.yaml
echo ""
echo "------------------------"
echo "Creating staging rolebinding"
echo "------------------------"
echo ""
kubectl -n sockshop-staging create rolebinding default-view --clusterrole=view --serviceaccount=sockshop-staging:default