#!/bin/bash
# Simple script for setting the Dynatrace credentials as environment variables

## Set TENANT and API TOKEN
# ---- Define Dynatrace Environment ----
# Sample: https://{your-domain}/e/{your-environment-id} for managed or https://{your-environment-id}.live.dynatrace.com for SaaS
DT_TENANT_URL=
# https://www.dynatrace.com/support/help/shortlink/token#create-an-api-token-
# Token in format dt0c01.STXXXX....
DT_API_TOKEN=
#DT_PAAS_TOKEN=
# DT_USER (Your login username in the environment, Click on the top right on the people icon and see your id, it can be your email or a username)
#DT_USER=julian.ruiz

# Magic IP for easytravel. Example if public ip == 1.2.3.4 then Magic IP => 1-2-3-4.nip.io 
#MIP_EASYTRAVEL=

# Magic IP for KIAB (Keptn in a Box). Example if public ip == 1.2.3.4 then Magic IP => 1-2-3-4.nip.io 
#MIP_KIAB=

# Call the function getEntityIds for setting the IDs. You'll need JQ, a Bash define the TenantURL and API_TOKEN 
#SERVICE_ID_CLASSIC=
#PG_ID_BACKEND=

#K8S CLUSTER INFO
K8S_API_ENDPOINT_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' --kubeconfig ~/.kube/config)
K8S_BEARER_TOKEN=$(kubectl get secret $(kubectl get sa dynatrace-monitoring -o jsonpath='{.secrets[0].name}' -n dynatrace --kubeconfig ~/.kube/config) -o jsonpath='{.data.token}' -n dynatrace --kubeconfig ~/.kube/config | base64 --decode)

#echo "usage 'source set_dt_variables.sh'"

SOCKSHOP_PROD_IP=$(kubectl get svc/front-end -n sockshop-production -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
SOCKSHOP_PROD_PORT=$(kubectl get svc/front-end -n sockshop-production -o jsonpath='{.spec.ports[0].port}')
SOCKSHOP_PROD_URL=$SOCKSHOP_PROD_IP":"$SOCKSHOP_PROD_PORT

#AWS tokens
AWS_ACCESS_KEY=
AWS_SECRET_KEY=

# FUNCTIONS DECLARATIONS
timestamp() {
  date +"[%Y-%m-%d %H:%M:%S]"
}

printInfo() {
    echo "[INFO] $(timestamp) |>->-> $1 <-<-<|"
}

printError() {
    echo "[ERROR] $(timestamp) |>->-> $1 <-<-<|"
}

printInfoSection() {
    echo "[INFO] $(timestamp) |$thickline"
    echo "[INFO] $(timestamp) |$halfline $1 $halfline"
    echo "[INFO] $(timestamp) |$thinline"
}

dynatracePrintValidateCredentials() {
    printInfoSection "Printing Dynatrace Credentials"
    if [ -n "${DT_TENANT_URL}"  ] &&  [ -n "${DT_API_TOKEN}"  ] &&  [ -n "${DT_USER}"  ] ; then
        printInfo "-------------------------------"
        printInfo "Dynatrace Tenant"
        printInfo "Dynatrace API Token"
        printInfo "K8s cluster API"
        printInfo "K8s cluster Bearer Token"
        printInfo "Sockshop prod IP"
        printInfo "Sockshop prod URL"
        printInfo "AWS Access key"
        printInfo "AWS Secret Access key"
 else
        printError "Dynatrace Variables not set, check your variables"
        printError "Dynatrace Tenant"
        printError "Dynatrace API Token"
        printInfo "K8s cluster API"
        printInfo "K8s cluster Bearer Token"
        printInfo "Sockshop prod IP"
        printInfo "Sockshop prod URL"
        printInfo "AWS Access key"
        printInfo "AWS Secret Access key"
    fi
}

exportVariables() {
    export DT_TENANT_URL
    export DT_API_TOKEN
    export K8S_API_ENDPOINT_URL
    export K8S_BEARER_TOKEN
    export SOCKSHOP_PROD_IP
    export SOCKSHOP_PROD_URL
    export AWS_ACCESS_KEY
    export AWS_SECRET_KEY
}

setMonacoNewCli(){
    printInfo "Setting monaco new CLI 'NEW_CLI=1'"
    export NEW_CLI=1
}

getEntityIds(){
    printInfoSection "Getting the SERVICE-ID of the ReverseProxy of the Classic Application via cURL API"
    SERVICE_ID_CLASSIC=$(curl -s GET "$DT_TENANT_URL/api/v2/entities?entitySelector=type(%22SERVICE%22),tag(%22classic-eval%22)&Api-Token=$DT_API_TOKEN" | jq -r '.entities[0].entityId')
    printInfo "SERVICE_ID:$SERVICE_ID_CLASSIC"

    printInfoSection "Getting the PROCESS-GROUP-ID of the Backend of the EasyTravel Application via cURL API"
    PG_ID_BACKEND=$(curl -s GET "$DT_TENANT_URL/api/v2/entities?entitySelector=type(%22PROCESS_GROUP%22),tag(%22Stage:Staging%22),tag(%22EasyTravel:BackEnd%22),entityName(%22backend%22)&Api-Token=$DT_API_TOKEN" | jq -r '.entities[0].entityId')
    printInfo "PG_ID_BACKEND:$PG_ID_BACKEND"
}

#getEntityIds

dynatracePrintValidateCredentials

exportVariables

setMonacoNewCli