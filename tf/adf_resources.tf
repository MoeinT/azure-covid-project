resource "azurerm_data_factory" "covid-reporting-df" {
  name                = "covrepdf${local.my_name}"
  location            = azurerm_resource_group.covid-reporting-rg.location
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
}

#Link adf to the source (azure blob storage)
resource "azurerm_data_factory_linked_service_azure_blob_storage" "adf-link-source" {
  name              = "ls_ablobs_covrep${local.my_name}"
  data_factory_id   = azurerm_data_factory.covid-reporting-df.id
  connection_string = azurerm_storage_account.covid-reporting-sa.primary_connection_string
}

#Lind adf to the target (dlg2)
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "adf-link-target" {
  name                = "ls_adls_covrep${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  url                 = "https://${azurerm_storage_account.covid-reporting-sa-dl.name}.dfs.core.windows.net"
  storage_account_key = azurerm_storage_account.covid-reporting-sa-dl.primary_access_key
}


#Create a dataset for the source 
resource "azurerm_data_factory_dataset_delimited_text" "ds-source" {
  name                = "ds_population_${local.my_name}_gz"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.adf-link-source.name

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

#Create a dataset for the target
resource "azurerm_data_factory_dataset_delimited_text" "ds-target" {
  name                = "ds_population_${local.my_name}_tsv"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-population.name
    path        = "population"
    filename    = local.target_blob_name
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = "\t"
  row_delimiter       = "\n"
}

#Store your pipeline in Json and pass it to the resource to recreate it using IaC
data "template_file" "pipeline" {
  template = file(local.arm_pipeline_template)
}

# Create a pipeline passing the above json file
resource "azurerm_data_factory_pipeline" "pl_ingest_population" {
  name            = "pl_ingest_pop_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1
  activities_json = data.template_file.pipeline.template

  parameters = {
    EmailTo : "moin.torabi@gmail.com"
    Message : "There's an error regarding the number of columns!"
    ActivityName : "Copying Data"
  }

}

#Create a trigger that would run the pipeline when a blob arrives in a container
resource "azurerm_data_factory_trigger_blob_event" "example" {
  name                  = "adf_trigger_blobevent_${local.my_name}"
  data_factory_id       = azurerm_data_factory.covid-reporting-df.id
  storage_account_id    = azurerm_storage_account.covid-reporting-sa.id
  events                = ["Microsoft.Storage.BlobCreated"]
  blob_path_begins_with = "/${azurerm_storage_container.blob-container-population.name}/"
  blob_path_ends_with   = local.source_blob_name
  ignore_empty_blobs    = true
  activated             = true

  pipeline {
    name = azurerm_data_factory_pipeline.pl_ingest_population.name
  }

}
