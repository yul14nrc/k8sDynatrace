# Full Dynatrace demo in kubernetes 
Currently only supported gke - eks and aks still in development.
## 1. Prerequisites.
- kubectl cli installed.
- gcloud cli installed and gcloud init ran to set the credentials.
- Dynatrace free trial tenant.
- Create Dynatrace token using the following permissions:
    - PaaS integration - Installer download
    - Access problem and event feed, metrics, and topology
    - Read settings
    - Write settings
    - Read entities
    - Create ActiveGate token
    - Ingest metrics
    - Ingest logs
    - Ingest events
    - Ingest bizevents
## 2. Usage
1. the `setup.sh` script needs three different parameters to work properly:
    - gcp, azure or aws: this parameter is used to create all the infraestructure needed for the demo.
    - 1 or 2: 1 is to deploy an Dynatrace ActiveGate in a external VM, 2 is to deploy a Dynatrace ActiveGate inside the dynatrace namespace in the kubernetes cluster.
    - true or false: true is to create the infraestructure and deploy all Dynatrace components, false is to only create the infraestructure.