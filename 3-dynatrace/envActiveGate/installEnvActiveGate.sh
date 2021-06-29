#!/bin/bash

exec >/tmp/logfile.txt 2>&1

export GCP=false
export azure=false

http_response=$(curl -o /dev/null -s -w "%{http_code}\n" http://metadata.google.internal)
if [ $http_response == 200 ]; then
    export DT_TENANT_ID=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/tenant_id -H "Metadata-Flavor: Google")
    export DT_ENVIRONMENT_ID=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/environment_id -H "Metadata-Flavor: Google")
    export DT_PAAS_TOKEN=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/paas_token -H "Metadata-Flavor: Google")
    export VM_FULL_ZONE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google")
    VM_ZONE=$(echo $VM_FULL_ZONE | cut -d'/' -f 4)
    GCP=true
fi

if [ $GCP == false ]; then
    http_response=$(curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance/compute/azEnvironment?api-version=2018-10-01&format=text")
    if [[ $http_response =~ "AzurePublicCloud" ]]; then
        azure=true
        export DT_TENANT_ID=$1
        export DT_PAAS_TOKEN=$2
    fi
fi

if [ -z "$DT_ENVIRONMENT_ID" ]; then
    echo "Environment ID Empty, SaaS Deployment"
    export DT_TENANT_URL="https://$DT_TENANT_ID.live.dynatrace.com"
else
    echo "Environment ID is $DT_ENVIRONMENT_ID, Managed Deployment"
    export DT_TENANT_URL="https://$DT_TENANT_ID.dynatrace-managed.com/e/$DT_ENVIRONMENT_ID"
fi

if [[ -f "Dynatrace-ActiveGate-Linux.sh" ]]; then
    rm -f Dynatrace-ActiveGate-Linux.sh
    echo "Removed Dynatrace-ActiveGate-Linux.sh"
fi

echo "Downloading ActiveGate..."
sudo curl -o Dynatrace-ActiveGate-Linux.sh -X GET "$DT_TENANT_URL/api/v1/deployment/installer/gateway/unix/latest?arch=x86&flavor=default" -H "Authorization: Api-Token $DT_PAAS_TOKEN"

if [[ -f "Dynatrace-ActiveGate-Linux.sh" ]]; then
    echo "ActiveGate File is downloaded"
    echo "AG Install Starting..."
    if [ $GCP == true ]; then
        #sudo nohup /bin/sh /Dynatrace-ActiveGate-Linux.sh &
        sudo /bin/sh ./Dynatrace-ActiveGate-Linux.sh
        echo "AG Install Complete"
    fi
    if [ $azure == true ]; then
        chmod +x ./Dynatrace-ActiveGate-Linux.sh
        sudo /bin/sh ./Dynatrace-ActiveGate-Linux.sh
        echo "AG Install Complete"
    fi
else
    echo "Downloading again..."
    sudo curl -o Dynatrace-ActiveGate-Linux.sh -X GET "$DT_TENANT_URL/api/v1/deployment/installer/gateway/unix/latest" -H "accept: application/octet-stream" -H "Authorization: Api-Token $DT_PAAS_TOKEN"
fi

#echo "Waiting for AG to start"
#sleep 40

#sudo service dynatracegateway start

#sleep 20

echo '[collector]' >>/var/lib/dynatrace/gateway/config/custom.properties
echo 'MSGrouter=true' >>/var/lib/dynatrace/gateway/config/custom.properties
echo "" >>/var/lib/dynatrace/gateway/config/custom.properties
echo '[http.client.external]' >>/var/lib/dynatrace/gateway/config/custom.properties
echo 'hostname-verification=no' >>/var/lib/dynatrace/gateway/config/custom.properties
echo 'certificate-validation=no' >>/var/lib/dynatrace/gateway/config/custom.properties
echo "" >>/var/lib/dynatrace/gateway/config/custom.properties
echo '[cloudfoundry_monitoring]' >>/var/lib/dynatrace/gateway/config/custom.properties
echo 'cloudfoundry_monitoring_enabled=false' >>/var/lib/dynatrace/gateway/config/custom.properties
echo "" >>/var/lib/dynatrace/gateway/config/custom.properties
echo '[vmware_monitoring]' >>/var/lib/dynatrace/gateway/config/custom.properties
echo 'vmware_monitoring_enabled=false' >>/var/lib/dynatrace/gateway/config/custom.properties
echo "" >>/var/lib/dynatrace/gateway/config/custom.properties
echo '[dbAgent]' >>/var/lib/dynatrace/gateway/config/custom.properties
echo 'dbAgent_enabled=false' >>/var/lib/dynatrace/gateway/config/custom.properties
echo "" >>/var/lib/dynatrace/gateway/config/custom.properties
echo '[rpm]' >>/var/lib/dynatrace/gateway/config/custom.properties
echo 'rpm_enabled=false' >>/var/lib/dynatrace/gateway/config/custom.properties

if [ $GCP == true ]; then
    echo "" >>/var/lib/dynatrace/gateway/config/custom.properties
    echo '[aws_monitoring]' >>/var/lib/dynatrace/gateway/config/custom.properties
    echo 'aws_monitoring_enabled=true' >>/var/lib/dynatrace/gateway/config/custom.properties
    echo "" >>/var/lib/dynatrace/gateway/config/custom.properties
    echo '[azure_monitoring]' >>/var/lib/dynatrace/gateway/config/custom.properties
    echo 'azure_monitoring_enabled=false' >>/var/lib/dynatrace/gateway/config/custom.properties
fi

if [ $azure == true ]; then
    echo "" >>/var/lib/dynatrace/gateway/config/custom.properties
    echo '[aws_monitoring]' >>/var/lib/dynatrace/gateway/config/custom.properties
    echo 'aws_monitoring_enabled=false' >>/var/lib/dynatrace/gateway/config/custom.properties
    echo "" >>/var/lib/dynatrace/gateway/config/custom.properties
    echo '[azure_monitoring]' >>/var/lib/dynatrace/gateway/config/custom.properties
    echo 'azure_monitoring_enabled=true' >>/var/lib/dynatrace/gateway/config/custom.properties
fi

sudo service dynatracegateway restart
