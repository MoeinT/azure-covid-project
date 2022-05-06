# Azure Covid Project

## Scope 

- The goal in this project is to create a data platform for reporting and predictions of Covid19 outbreaks: 

- We will integrate and orchestrate our data pipelines using Azure Data Factory. 

- We will create a dashboard using Azure Power BI to visualize the trend of Covid and the effectiveness of the Corona Virus tests being carried out. 

- We will also monitor our data pipeline and create alerts when there’s failure in the pipeline. 

## Cloud solution

- ### Data source
    - European Center for Disease prevention and control - Data related to the European population from Eurostat

- ### Data ingestion
    - We’ll use the HTTP connector within Azure Data Factory to get the data from the European Center for Disease Prevention and Control website. We’ll keep the population file in an Azure blob storage and ingest from there. An Azure blob storage is another connector to Azure Data Factory. 

- ### Transformation 

    - We’ll use Azure Data Factory to transform this data; we’ll use Data Flows within Azure Data Factory for our transformation of a few datasets.

      We’ll use HDinsight for another dataset, and Azure Databricks for another one. For the HDinsight and Databricks, ADF will mostly be an orchestration tool, rather than a transformation tool. 

      All the transformed data will be stored into an Azure Data Lake Storage Gen2 for ML models. We’ll also push a subset of the Data into a SQL database, for later use in reporting. 

      All the above 3 transformation techniques will run on distributed infrastructure and are easily scalable. Data flow is a code-free tool for low- to medium-level transformations. Both HDinsight and Databricks will require you to write code in one of Spark supported languages, i.e., Python, Scala etc. For HDinsight, we can also write code using a sql-like language called Hive and also a scripting language called Pig. 


## Storage solution

- ### Azure blob storage:
    - It can be used for storing semi-structured data such as text in a json format, or unstructured data such as images, audio, and videos. Here we  use a blob storage container to store the population data. We’ll keep some of the config files from the Azure Data Factory as well as the scripts for our HDinsight transformation inside this blob storage.

- ### Azure Data Lake Storage Gen2:
    - Will be the data lake in our project

- ### Azure SQL database:
    - This is used for our reporting platform for power BI. We could’ve used Azure Synapse Analytics, which is a good solution for large data analytics due to its parallel processing architecture; but in our case an Azure SQL database would be enough, since we’re processing a small amount of data. Here’s how our architecture and all the required resources look like: 
