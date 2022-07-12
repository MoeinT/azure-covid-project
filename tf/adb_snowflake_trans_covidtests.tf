#Create a dataset linking adf to processed covidtests data
resource "azurerm_data_factory_dataset_delimited_text" "ds_processed_covidtests" {
  name                = "ds_processed_covidtests_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.ls_processed_covidrep.name
  folder              = "processed"
  azure_blob_storage_location {
    container = azurerm_storage_container.processed-data.name
    path      = "ecdc/covidtests"
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = ","
  row_delimiter       = "\n"
}

# Create a dataset linking Azure data factory to a specific table 
resource "azurerm_data_factory_dataset_snowflake" "ds-covidtests-snowflake" {
  name                = "ds_covidtests_snowflake_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_snowflake.ls_snowflake.name
  folder              = "snowflake"
  schema_name         = "PUBLIC"
  table_name          = "COVIDTESTS"
}

resource "databricks_notebook" "covidtests_notebook" {
  source = local.covidtests_transformation_path
  path   = "/Covid/transformations/covidtests_transformation"
}

data "template_file" "pipelines-tansf-covidtests" {
  template = file(local.arm_pipeline_covidtests_trans)
}

# Create a pipeline to run the notebook we deployed above
resource "azurerm_data_factory_pipeline" "pl_adb_covidtests_data" {
  name            = "pl_adb_covidtests_data_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1
  folder          = "Process_copy"
  activities_json = data.template_file.pipelines-tansf-covidtests.template
}