<details>
  <summary>Table of Contents</summary>
  <ol>
    <ul>
     <li><a href="#azure-covid-reporting">Azure Covid Reporting</a></li>
     <li><a href="#scope">Scope</a></li>
     <li>
        <a href="#Data-Ingestion">Data Ingestion</a>
         <ul>
          <li><a href="#Population-dataset">Population dataset</a></li>
          <li><a href="#Covid19-dataset">Covid19 dataset</a></li>
         </ul>
     </li>
     <li><a href="#Data-Transformation">Data Transformation</a></li>
     <li><a href="#Loading-in-Snowflake">Data Transformation</a></li>
     <li><a href="#Triggers">Data Transformation</a></li>
     <li>
        <a href="#infrastructure-as-code (IaC)">Infrastructure as code (IaC)</a>
         <ul>
          <li><a href="#validating terraform using github action">Validating IaC with Terraform using Github action</a></li>
          <li><a href="#deployment">Deployment</a></li>
        </ul>
    </li>
         </ul>
    <ul>
     <li><a href="#contact">Contact</a></li>
     <li><a href="#acknowledgments">Acknowledgments</a></li>
    </ul>
  </ol>
</details>


## Azure Covid Reporting

## Scope

The goal of this project is to create a data platform in Azure and Snowflake for reporting and predictions of Covid19 outbreaks. Here's the scope of the project:

- We will create all the required insfrastructure in Azure using Terraform. Terraform is a tool used to programmatically provision and manage infrastructure in the cloud as well as on-prem

- We use Github CI/CD actions to validate our Terraform code and preview the changes to our infrastructure on a pull-request and deploy our infrastructure upon merging to main

- We will use the Databricks platform within Azure to process our data; we use Terraform to create and maintain our workspaces and clusters as well as deploy our Python notebooks

- We will create pipelines in Azure data factory (adf) to ingest our data from the ECDC (European Centre for Disease Prevention and Control) website, process our Databricks notebooks, and finally copy the transformed data in a database in Snowflake. We will integrate and orchestrate all our data pipelines using Azure Data Factory

- We will monitor our data pipelines and create alerts when there is a failure in any of the pipelines using Azure monitor

## Data Ingestion

### Population dataset

Downloaded the data related to the European population from the Eurostat website

### Covid19 dataset

Ingested the following data from the [ECDC](https://www.ecdc.europa.eu/en/covid-19/data) website into Azure Data Factory through an HTTP connector and sent the results into an Azure Data Lake Storage Gen2.  

- New Cases and Deaths by Country 
- Hospital Admissions and ICU Cases
- Covid Testing 
- Country Responses to Covid19

## Data Transformation

- Used the Databricks platform within Azure and used PySpark for all our data transformations. All our Databricks resources have been managed using IaC with Terraform. See our PySpark codes for all the above data [here in this repository](https://github.com/MoeinT/azure-covid-project/tree/main/scripts).

## Loading in Snowflake

- Snowflake is a cloud-based datawarehouse. Snowflake has been gaining popularity due to some of its advanced functionalities, such as its ability to access data in structured and unstructured formats. For this reason, we've used Snowflake as our datawarehouse solution in this project. In this project, we've created a [LinkedService](https://docs.microsoft.com/en-us/azure/data-factory/connector-snowflake?tabs=data-factory) in adf pointing towards a specific database in Snowflake and used the [Copy Activity](https://docs.microsoft.com/en-us/azure/data-factory/copy-activity-overview) in adf to send our data from an azure blob storage into snowflake.

## Triggers 

- Created triggers that would run the above pipelines on a weekly basis, since the ECDC data gets updated every week. We also used the [Execute Pipeline Activity in adf](https://docs.microsoft.com/en-us/azure/data-factory/control-flow-execute-pipeline-activity) to create dependencies between our pipelines, i.e., first the ingestion pipeline should run before the transformation and loading pipelines get triggered. 

## Infrastructure as code (IaC)

Infrastructure as Code (IaC) is the management of infrastructure (networks, virtual machines, storages etc.) in a descriptive model using code. Using IaC we can avoid manual configuration of environments and enforce consistency by representing the desired state of their environments via code. [Terraform](https://learn.hashicorp.com/tutorials/terraform/infrastructure-as-code) is HashiCorp's infrastructure as code tool. It lets you define resources and infrastructure in human-readable, declarative configuration files, and manages your infrastructure's lifecycle.

### Validating IaC with Terraform using Github actions
When we use IaC with Terraform (or any other language), the goal is to reliably deploy and manage infrastructure using software development practices. The goal of Terraform validation is to catch and resolve issues as early as possible in the development process before they find their way into production. Here in this repository, I've created all the resources for my project using Terraform, and added the following tests: 

- **Syntax**

    There are two kinds of syntax errors, language syntax, such as forgetting to close a curly bracket, or logical errors, such as calling a resource that has not been provisioned yet. Terraform can catch this errors by running ```terraform validate```.
- **Format**

    When there are multiple people working on IaC, it becomes important to rewrite your Terraform configuration files to a canonical format and style before deploying them in production. You can check this using ```terraform fmt -check -recursive```. 
- **Planning**

    Before applying any changes to your infrastructure, Terraform can look at your configuration and generated a plan. It will tell you what resources are going to be destroyed and what resources are going to be generated. You can preview the changes to your infrastructure using the ```terraform plan``` command. Terraform plan is a crucial step in your terraform execution workflow. 
    
### Deployment 
If all the above steps are successfuly run, then we're ready to deploy our infrastructure in production. We can do so by using the ```terraform apply``` command. [Here](https://github.com/MoeinT/azure-covid-project/blob/feat/terraform_actions/.github/workflows/terraform.yaml) you can see my Github workflow that would run all the necessary tests. Upon each change, a pull request needs to be created that would trigger the ```terraform plan``` command; if that runs successfully and the changes get merged to main, then the ```terraform apply``` command would be triggered and the changes get deployed in production. This is a standard procedure to fully manage your resources using terraform and validate your codes using Github actions. 


## Contact
Moein Torabi - moin.torabi@gmail.com 

Find me on [LinkedIn](https://www.linkedin.com/in/moein-torabi-5339b288/)
<p align="right">(<a href="#top">back to top</a>)</p>

## Acknowledgments
* [Terraform documentation](https://www.terraform.io/docs)
* [Get started with Terraform](https://learn.hashicorp.com/terraform)
* [Terraform concepts explained](https://www.youtube.com/watch?v=l5k1ai_GBDE)
* [Validating Terraform Code with GitHub Actions](https://www.youtube.com/watch?v=2Zwrtn-QPk0)
<p align="right">(<a href="#top">back to top</a>)</p>



[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/moein-torabi-5339b288/