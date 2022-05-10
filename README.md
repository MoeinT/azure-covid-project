[![LinkedIn][linkedin-shield]][linkedin-url]

<details>
  <summary>Table of Contents</summary>
  <ol>
    <ul>
     <li><a href="#azure-covid-reporting">Azure Covid Reporting</a></li>
     <li><a href="#scope">Scope</a></li>
     <li>
        <a href="#infrastructure-as-code (IaC)">Infrastructure as code (IaC)</a>
         <ul>
          <li><a href="#validating-IaC-with-terraform-using-github-action">Validating IaC with Terraform using Github action</a></li>
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

The goal of my project is to create a data platform in Azure for reporting and predictions of Covid19 outbreaks. Here's the scope of the projec  

- We will integrate and orchestrate our data pipelines using Azure Data Factory

- We will create a dashboard using Azure Power BI to visualize the trend of Covid and the effectiveness of the Corona Virus tests being carried out

- We will also monitor our data pipeline and create alerts when there’s failure in the pipeline

The first step in the project is to provision all the required resources on Azure. See below for a more detailed plan.

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

Project Link: [Azure Covid Reporting](https://github.com/MoeinT/azure-covid-project)
<p align="right">(<a href="#top">back to top</a>)</p>

## Acknowledgments

Use this space to list resources you find helpful and would like to give credit to. I've included a few of my favorites to kick things off!

* [Terraform documentation](https://www.terraform.io/docs)
* [Get started with Terraform](https://learn.hashicorp.com/terraform)
* [Terraform concepts explained](https://www.youtube.com/watch?v=l5k1ai_GBDE)
* [Validating Terraform Code with GitHub Actions](https://www.youtube.com/watch?v=2Zwrtn-QPk0)
<p align="right">(<a href="#top">back to top</a>)</p>



[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/moein-torabi-5339b288/