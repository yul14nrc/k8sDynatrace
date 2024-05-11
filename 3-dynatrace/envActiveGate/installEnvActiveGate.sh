#!/bin/bash

exec >/tmp/logfile.txt 2>&1

export GCP=false
export azure=false
export AWS=false

http_response=$(curl -o /dev/null -s -w "%{http_code}\n" http://metadata.google.internal)
if [ $http_response == 200 ]; then
    export DT_TENANT_ID=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/tenant_id -H "Metadata-Flavor: Google")
    export DT_ENVIRONMENT_ID=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/environment_id -H "Metadata-Flavor: Google")
    export DT_API_TOKEN=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/api_token -H "Metadata-Flavor: Google")
    export VM_FULL_ZONE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google")
    VM_ZONE=$(echo $VM_FULL_ZONE | cut -d'/' -f 4)
    GCP=true
fi

if [[ $GCP == false && $AWS == false ]]; then
    cloud_type=$(uname -a | cut -d' ' -f 3)
    if [[ $cloud_type =~ "azure" ]]; then
        azure=true
        export DT_TENANT_ID=$1
        export DT_API_TOKEN=$2
    fi
fi

if [[ $azure == false && $GCP == false ]]; then
    echo "AWS"
    AWS=true
fi

if [ -z "$DT_ENVIRONMENT_ID" ]; then
    echo "Environment ID Empty, SaaS Deployment"
    export DT_TENANT_URL="https://$DT_TENANT_ID.live.dynatrace.com"
else
    echo "Environment ID is $DT_ENVIRONMENT_ID, Managed Deployment"
    export DT_TENANT_URL="https://$DT_TENANT_ID.dynatrace-managed.com/e/$DT_ENVIRONMENT_ID"
fi

if [[ -f "Dynatrace-ActiveGate-Linux.sh" ]]; then
    sudo rm -f Dynatrace-ActiveGate-Linux.sh
    echo "Removed Dynatrace-ActiveGate-Linux.sh"
fi

echo "Downloading ActiveGate..."
sudo curl -o Dynatrace-ActiveGate-Linux.sh -X GET "$DT_TENANT_URL/api/v1/deployment/installer/gateway/unix/latest?arch=x86&flavor=default" -H "Authorization: Api-Token $DT_API_TOKEN"

if [[ -f "Dynatrace-ActiveGate-Linux.sh" ]]; then
    echo "ActiveGate File is downloaded"
    echo "AG Install Starting..."
    if [ $GCP == true ]; then
        #sudo nohup /bin/sh /Dynatrace-ActiveGate-Linux.sh &
        sudo /bin/bash ./Dynatrace-ActiveGate-Linux.sh
        echo "AG Install Complete"
    fi
    if [ $azure == true ]; then
        chmod +x ./Dynatrace-ActiveGate-Linux.sh
        sudo /bin/bash ./Dynatrace-ActiveGate-Linux.sh
        echo "AG Install Complete"
    fi
else
    echo "Downloading again..."
    sudo curl -o Dynatrace-ActiveGate-Linux.sh -X GET "$DT_TENANT_URL/api/v1/deployment/installer/gateway/unix/latest" -H "accept: application/octet-stream" -H "Authorization: Api-Token $DT_API_TOKEN"
fi
