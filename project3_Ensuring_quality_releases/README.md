# Ensuring Quality Releases - Project

This project focuses on leveraging industry-leading tools, particularly Microsoft Azure, to establish a robust pipeline for creating disposable test environments, running automated tests effortlessly, and ensuring the quality of software releases.

## Overview

### Pipeline Resources

This CI/CD pipeline will generate the following essential resources:

* Resource Group
* App Service
* Virtual Network
* Network Security Group
* Virtual Machine

These resources are orchestrated to deploy a demo REST API within the App Service, while comprehensive automated tests are executed against the REST API from a virtual machine created using Terraform in the CI/CD pipeline.

### Tests

The pipeline includes automated tests developed using 
* *Postman* for API testing (Integration Testing)
* *JMeter* for Performance Testing
* *Selenium* using Chromedriver for Functional UI Testing

The final pipeline, described in the *azure-pipelines.yaml* file, guides you through integrating these tests seamlessly.

## Set up

## Dependencies

The following are the dependencies of the project you will need:

- Install the following tools:
  - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
  - [Terraform](https://www.terraform.io/downloads.html)
  - [JMeter](https://jmeter.apache.org/download_jmeter.cgi)
  - [Postman](https://www.postman.com/downloads/)
  - [Python](https://www.python.org/downloads/)
  - [Selenium](https://www.selenium.dev/)
  - [Chrome](https://www.google.com/intl/de_de/chrome/)

In [Azure Devops](https://dev.azure.com), you also need to install this dependencies:
* [Terraform](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks)
* [Jmeter tasks](https://marketplace.visualstudio.com/items?itemName=AlexandreGattiker.jmeter-tasks)
* [PublishHTMLReports](https://marketplace.visualstudio.com/items?itemName=LakshayKaushik.PublishHTMLReports)

## Instructions

### Login with Azure CLI

First, login to the Azure CLI using:

```bash
az login
```

In Azure, you need to create a resource group that takes all resources build for this project. For the project, I have used *Azuredevops*.

## Run Packer image for VM

To provide the image for the VM, we will create with Terraform, there must be image specified. First, you need to update the variables defined in *packer-image.json*:

```json
    "variables": {
        "subscription_id": "...",
        "tenant_id": "...",
        "client_id": "...",
        "client_secret": "...",   
        "resource_group_name": "...", # e.g. Azuredevops
        "image_name": "packer-image",
        "vm_size": "..."
    }
```

Once the variables have been provided, the image for the VM will be then created with running 
```cmd
packer build ./packer-image.json
```

If you want to retrieve the information from that image after the creation again, you can run 
*get_imageid.sh* at terraform/environments/test/. Make sure to update the credentials inside of the file:

```bash
subscription_id="..."
resource_group="..." # e.g. Azuredevops
image_name="packer-image"
```

![Packer Image](screenshots/packer-image.png)

### Configure the storage account and state backend

Terraform supports the persisting of state in remote storage. See [Tutorial: Store Terraform state in Azure Storage](https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage) for details or follow the instructions below.

Firstly, execute the `create-tf-storage.sh` script:

```bash
bash create-tf-storage.sh
```
Be aware that this creates the tf storage specified in the file as
```bash
RESOURCE_GROUP_NAME="..." # e.g. Azuredevops
```

This will create a storage in the resource group saving the *tfstate* and provide relevant information for setting up the Terraform files, e.g. an access key for the storage.

After that, update `terraform/main.tf` with the Terraform storage account and state backend configuration variables:

- `storage_account_name`: The name of the Azure Storage account
- `container_name`: The name of the blob container
- `key`: The name of the state store file to be created

```bash
terraform {
  backend "azurerm" {
    storage_account_name = "tfstate..." # number of created tf storage
    container_name       = "tfstate" 
    key                  = "test.terraform.tfstate"
    access_key           = "..." # access key provided by the created tf storage
  }
}
```

If you want to retrieve the access key from that image after the creation again, you can run 
*get_key.sh* at terraform/environments/test/. Make sure to update the credentials inside of the file:
```bash
STORAGE_ACCOUNT_NAME="tfstate..." # insert number of created tf storage
RESOURCE_GROUP="... " # e.g. Azuredevops
```

### Configuring Terraform

Update the following values in `terraform.tfvars` as required:

```bash
# Azure subscription vars
subscription_id = "..." # service principal id
tenant_id = "..."
client_id = "..." # application id
client_secret = "..." # secret key

# Resource Group/Location
location = "..." # location where the resource group is located at
resource_group = "..." # e.g. Azuredevops
application_type = "..."

# Network
virtual_network_name = "..."
address_space = ["..."]
address_prefix_test = "..."

# VM
vm_admin_username = "..."
packer_image = "/subscriptions/.../resourceGroups/Azuredevops/providers/Microsoft.Compute/images/packer-image" # provide the same resource group as above (VM uses this image)
```

Also, generate an SSH key pair in the Azure command shell on https://portal.azure.com
```bash
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub
```
Provide this key in terraform/modules/vm for *vm.tf*:
```bash
  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = "..." # starts with "ssh-rsa"
  }
```

### Executing Terraform

Terraform creates the following resources for a specific environment tier:

- App Service
- App Service Plan
- Network
- Network Security Group
- Public IP
- Resource Group
- VM (uses the packer image provided)

The CD pipeline will following commands in terraform/environments/test to create the infrastructure:

```bash
terraform init
terraform validate
terraform apply
```

### Setting up Azure DevOps

### Create a Service Principal for Terraform

A Service Principal is an application within Azure Active Directory whose authentication tokens can be used as the `client_id`, `client_secret`, and `tenant_id` fields needed by Terraform (`subscription_id` can be independently recovered from your Azure account details). See [Azure Provider: Authenticating using a Service Principal with a Client Secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret) for details

 In Azure Pipelines, you can run parallel jobs on Microsoft-hosted infrastructure or your own (self-hosted) infrastructure. For this project, I have set up a self-hosted agent. Go to https://dev.azure.com and do following steps:
 * Create a new project.
 * Create a personal access token (PAT) in Azure DevOps and copy that PAT locally on your PC. you will need this to set up your agent on the VM for the "Build" step.
 * Set up a service connection named `mySC` with access to all pipelines (Project -> Project settings).
 * Create an agent pool named `myAP` with access to all pipelines. Add an agent automatically with the Azure resource manager. Add this agent to a new VM in the same resource group. This VM will run the "Build" step.
 * Create a new environment `test-vm` (Azure Pipelines -> Environments) and provide it to another new VM in the same resource group. This VM will run the "Deploy" and "Test" parts.
 * Create a new pipeline. Select GitHub and then your GitHub repository. Configure your pipeline by choosing "Existing Azure Pipelines YAML File" and select the `azure-pipelines.yaml` file in the menu that pops out on the right.

On the Review page, update the Terraform variables:

```yaml
variables:
  python.version: '...' # Python version the VMs are running on
  azureServiceConnectionId: 'mySC'
  projectRoot: $(System.DefaultWorkingDirectory)
  environmentName: 'test-vm'
  tfstatenumber: 'tfstate...' # number of created tf storage
  tfrg: '...' # resource group for all files
  application_type: '...'  # name of the project given in dev.azure.com
```

Once the pipeline will run the "Build" step, it will provide the Terraform resources:
![terraform init](screenshots/terraform-init.png)
![terraform validate](screenshots/terraform-validate.png)
![terraform apply](screenshots/terraform-apply.png)

When having run the pipeline up to the "Deploy" step, the FakeRestAPI will be deployed as an app service at URL defined at terraform/modules/appservice in *appservice.tf*:
```bash
name = "${var.application_type}-${var.resource_type}"
```

So if you use for instance 
```bash
application_type = "project-qa"
```

the web app will be named `project-qa-Appservice` and will be hosted at https://project-qa-appservice.azurewebsites.net

When opening this URL after deployment, it will look like that:
![FastRestAPI](screenshots/fastrestapi.png)

### Automated testing

#### Integration testing with Postman

Screenshots of the Test Run Results from Postman shown in Azure DevOps:

* *Data Validation Test*: Ensures the integrity and accuracy of the data exchanged between the client and the server by verifying that the response received meets expected criteria 
![Postman Data Validation Test](screenshots/postman-datavalid.png)

* *Regression Test*: Verifies that recent code changes have not adversely affected existing API functionalities by systematically retesting a suite of previously validated requests and ensuring they still produce the expected responses.
![Postman Regression Test](screenshots/postman-regression.png)

#### Performance testing with JMeter

Log outputs of JMeter when executed by the CI/CD pipeline:

* *Stress Test*: Evaluates the system's robustness and performance under high loads by simulating a large number of concurrent users or heavy transaction volumes to identify potential bottlenecks and assess system stability.
![Jmeter Stress Test](screenshots/jmeter-stress.png)

* *Endurance Test*: Measures the system's ability to sustain prolonged, continuous loads over an extended period, ensuring that performance remains stable and reliable under sustained usage conditions, helping to identify any gradual degradation or resource leaks.
![Jmeter Endurance Test](screenshots/jmeter-endurance.png)

#### Funktional UI testing with Selenium

The selenium test will be performed on a different web app (https://www.saucedemo.com/):
![Selenium Test](screenshots/selenium_test.png)


Overall, the pipeline execution should look like this:
![CICD pipepine runthrough successful](screenshots/cicd_success.png)
![CICD pipepine artifaczs](screenshots/cicd_artifacts.png)
![CICD pipepine Test summary](screenshots/cicd_testsummary.png)
![CICD Test runs](screenshots/cicd_testruns.png)

### Monitoring & Observability

### Azure Monitor

Go to the Azure Portal, select your application service and create a new alert in the "Monitoring" group:

Execute the Azure Pipeline to trigger an alert.

![Alerts](screenshots/alerts.png)
![Alert "request" KQL](screenshots/alert_kql.png)
![Appservice metrics "requests"](screenshots/appservice_metrics.png)

### Configure Azure Log Analytics

#### Setting up custom logs

Download the *selenium-test.log* artifact from Azure Devops
![selenium-test.log Artifact](screenshots/seleniumlog_artifact.png)

Go to the Azure Portal to Azure Log Analytics workspaces and set up an agent on the VM the test step where the Selenium test will be performed and install an agent on it. For that, you need to connect this VM to Log Analytics and create a Data Collection Rule including the logs on it.
![Log Analytics connected VMs](screenshots/la_connectedVMs.png)
![Log Analytics connected Data sSts](screenshots/linuxsyslog.png)

Then go to ***Logs*** and create a new custom log. Upload *selenium-test.log*. Then select "Timestamp" `YYYY-MM-DD HH:MM:SS` as the record delimiter and add the path of *selenium-test.log* of the VM the step has been performed on as the log collections path (it can some time for the VM to be able to collect the logs).
![selenium log found on VM](screenshots/vm_seleniumlog.png)

![Log Analytics path for selenium-test.log Artifact](screenshots/linuxpath.png)

#### Querying custom logs

To query the custom logs, go to "Logs" in the "General" group of your Log Analytics workspace.

Select your custom log and run it:
![selenium.log Custom Log KQL](screenshots/selenium_cl.png)

## Clean-up

Destroy the Terraform resources:

```bash
cd terraform
terraform destroy
```
