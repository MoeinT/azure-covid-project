# Azure Covid Project

## Scope 

- The goal in this project is to create a data platform for reporting and predictions of Covid19 outbreaks

- We will integrate and orchestrate our data pipelines using Azure Data Factory. 

- We will create a dashboard using Azure Power BI to visualize the trend of Covid and the effectiveness of the Corona Virus tests being carried out. 

- We will also monitor our data pipeline and create alerts when there’s failure in the pipeline. 

## Infrastructure as code (IaC)

Infrastructure as Code (IaC) is the management of infrastructure (networks, virtual machines, storages etc.) in a descriptive model using code. Using IaC we can avoid manual configuration of environments and enforce consistency by representing the desired state of their environments via code. [Terraform](https://learn.hashicorp.com/tutorials/terraform/infrastructure-as-code) is HashiCorp's infrastructure as code tool. It lets you define resources and infrastructure in human-readable, declarative configuration files, and manages your infrastructure's lifecycle.

### Validating IaC with Terraform using Github action
When we use IaC with Terraform (or any other language), the goal is to reliably deploy and manage infrastructure using software development practices. The goal of Terraform validation is to catch and resolve issues as early as possible in the development process before they find their way into production. Here in this repository, I've created all the resources for my project using Terraform, and added the following tests: 

- **Syntax**

    There are two kinds of syntax errors, language syntax, such as forgetting to close a curly bracket, or logical errors, such as calling a resource that has not been provisioned yet. Terraform can catch this errors by running ```terraform validate```