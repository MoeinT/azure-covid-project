#########################################pl_execution_population

data "template_file" "pipeline_execution_pop" {
  template = file(local.arm_pipeline_execution_population)
}

# Create a pipeline to run the notebook we deployed above
resource "azurerm_data_factory_pipeline" "pl_execute_population_pipelines" {
  name            = "pl_execute_population_pipelines_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1
  folder          = "Execution"
  activities_json = data.template_file.pipeline_execution_pop.template
}


#Create a trigger that would run the population execution pipeline
resource "azurerm_data_factory_trigger_blob_event" "example" {
  name                  = "tr_population_arrived_${local.my_name}"
  data_factory_id       = azurerm_data_factory.covid-reporting-df.id
  storage_account_id    = azurerm_storage_account.covid-reporting-sa.id
  events                = ["Microsoft.Storage.BlobCreated"]
  blob_path_begins_with = "/${azurerm_storage_container.blob-container-population.name}/"
  blob_path_ends_with   = local.source_blob_name
  ignore_empty_blobs    = true
  activated             = true

  pipeline {
    name = azurerm_data_factory_pipeline.pl_execute_population_pipelines.name
  }

}

#########################################pl_execution_ecdc
data "template_file" "pl_execute_ecdc_trans_pipelines" {
  template = file(local.arm_pipeline_execution_ecdc_trans)
}

# Create a pipeline to run the notebook we deployed above
resource "azurerm_data_factory_pipeline" "pl_execute_ecdc_trans_pipelines" {
  name            = "pl_execute_ecdc_trans_pipelines_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1
  folder          = "Execution"
  activities_json = data.template_file.pl_execute_ecdc_trans_pipelines.template
}

#Create a scheduling trigger to execute the ecdc ingestion as well as all the transformations
resource "azurerm_data_factory_trigger_schedule" "tr-ecdc-ingest-transform" {
  name            = "tr_ecdc_ingest_trans_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  pipeline_name   = azurerm_data_factory_pipeline.pl_execute_ecdc_trans_pipelines.name

  start_time = "2022-07-05T22:00:00.00Z"

  #The ecdc data gets updated every week
  interval  = 1
  frequency = "Week"
  activated = "true"
}