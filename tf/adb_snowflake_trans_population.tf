#########################################Ingestion

#Create a dataset for the source population
resource "azurerm_data_factory_dataset_delimited_text" "ds-source" {
  name                = "ds_population_${local.my_name}_gz"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.adf-link-source.name
  folder              = "raw"
  azure_blob_storage_location {
    container = azurerm_storage_container.blob-container-population.name
    filename  = local.source_blob_name
  }
  first_row_as_header = true
  compression_codec   = "gzip"
  compression_level   = "Optimal"
  column_delimiter    = "\t"
  row_delimiter       = "\n"
}

#Create a dataset for the target population
resource "azurerm_data_factory_dataset_delimited_text" "ds-target" {
  name                = "ds_population_${local.my_name}_tsv"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name
  folder              = "raw"
  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-raw.name
    path        = "population"
    filename    = local.target_blob_name
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = "\t"
  row_delimiter       = "\n"
}

#Store your pipeline in Json and pass it to the resource to recreate it using IaC
data "template_file" "pipelines-pop" {
  template = file(local.arm_pipeline_population_ingest)
}

# Create a pipeline passing the above json file
resource "azurerm_data_factory_pipeline" "pl_ingest_population" {
  name            = "pl_ingest_pop_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1
  folder          = "Ingestion"
  activities_json = data.template_file.pipelines-pop.template

  parameters = {
    EmailTo : "moin.torabi@gmail.com"
    Message : "There's an error regarding the number of columns!"
    ActivityName : "Copying Data"
  }

}

#########################################Transformation

#PySpark code for population transformation
resource "databricks_notebook" "population_notebook" {
  source = local.population_transformation_path
  path   = "/Covid/transformations/population_transformation"
}

#Create a dataset linking adf to processed population data
resource "azurerm_data_factory_dataset_delimited_text" "ds_processed_populations" {
  name                = "ds_processed_populations_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.ls_processed_covidrep.name
  folder              = "processed"
  azure_blob_storage_location {
    container = azurerm_storage_container.processed-data.name
    path      = "population"
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = ","
  row_delimiter       = "\n"
}

# Create a dataset linking Azure data factory to a the population table in Snowflake
resource "azurerm_data_factory_dataset_snowflake" "ds-population-snowflake" {
  name                = "ds_population_snowflake_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_snowflake.ls_snowflake.name
  folder              = "snowflake"
  schema_name         = "PUBLIC"
  table_name          = "POPULATIONS"
}

data "template_file" "pipelines-tansf-pop" {
  template = file(local.arm_pipeline_population_trans)
}

# Create a pipeline to run the notebook we deployed above
resource "azurerm_data_factory_pipeline" "pl_adb_population_data" {
  name            = "pl_adb_population_data_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1
  folder          = "Process_copy"
  activities_json = data.template_file.pipelines-tansf-pop.template
}

