#!/bin/bash

CREDS=./creds.json
rm $CREDS 2>/dev/null

echo ""
echo -e "${YLW}Please enter the credentials as requested below: ${NC}"
echo ""
read -p "Dynatrace Tenant ID (ex. https://<TENANT_ID>.live.dynatrace.com or https://<TENANT_ID>.dynatrace-managed.com): " DTTEN
read -p "Dynatrace Environment ID (Dynatrace Managed Only - https://<TENANT_ID>.dynatrace-managed.com/e/<ENVIRONMENT_ID>): " DTENV
read -p "Dynatrace API Token: " DTAPI

echo ""
echo -e "${YLW}Please confirm all are correct: ${NC}"
echo ""
echo "Dynatrace Tenant ID: $DTTEN"
echo "Dynatrace Environment ID: $DTENV"
echo "Dynatrace API Token: $DTAPI"

echo ""
read -p "Is this all correct? (y/n) : " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm $CREDS 2>/dev/null
    cat ./creds.sav | sed 's~DYNATRACE_TENANT_ID~'"$DTTEN"'~' |
        sed 's~DYNATRACE_ENVIRONMENT_ID~'"$DTENV"'~' |
        sed 's~DYNATRACE_API_TOKEN~'"$DTAPI"'~' >>$CREDS
else
    exit 1
fi
echo ""
cat $CREDS
echo ""
echo ""
echo "The credentials file can be found here:" $CREDS
echo ""
