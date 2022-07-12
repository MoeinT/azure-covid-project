#Create a custom dataset for the source
resource "azurerm_data_factory_custom_dataset" "ds-source-ecdc" {
  name            = "ds_ecdc_raw_csv_http_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  type            = "DelimitedText"
  folder          = "raw"
  parameters = {
    relativeURL = ""
    baseURL     = ""
  }

  linked_service {
    name = azurerm_data_factory_linked_custom_service.adf-link-source-covid.name
    parameters = {
      sourceBaseURL = "@dataset().baseURL"
    }
  }

  type_properties_json = <<JSON
{
            "location": {
                "type": "HttpServerLocation",
                "relativeUrl": {
                    "value": "@dataset().relativeURL",
                    "type": "Expression"
                }
            },
            "columnDelimiter": ",",
            "rowDelimiter": "\n",
            "encodingName": "UTF-8",
            "escapeChar": "\\",
            "firstRowAsHeader": true,
            "quoteChar": "\""
}
JSON

}

#Create a dataset for the target
resource "azurerm_data_factory_dataset_delimited_text" "ds-target-ecdc" {
  name                = "ds_ecdc_raw_csv_http_dl${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name
  folder              = "raw"
  #Parameterize the filename
  parameters = {
    fileName = ""
  }

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-raw.name
    path        = "ecdc"
    filename    = "@dataset().fileName"
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = "\t"
  row_delimiter       = "\n"
}


#Container holding a json config file for the Lookup Activity
resource "azurerm_storage_container" "config" {
  name                  = "configslookup"
  storage_account_name  = azurerm_storage_account.covid-reporting-sa.name
  container_access_type = "private"
}

#Create a dataset pointing towards the above container
resource "azurerm_data_factory_dataset_json" "ds-config" {
  name                = "ds_ecdc_filelist_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.adf-link-source.name
  folder              = "raw"
  azure_blob_storage_location {
    container = azurerm_storage_container.config.name
    path      = "ecdc"
    filename  = local.config_filename
  }

  encoding = "UTF-8"

}

#Create a pipeline to ingest cases and death data
data "template_file" "pipelines-ecdc" {
  template = file(local.arm_pipeline_ecdc_template)
}
#pl_ingest_cases_death
resource "azurerm_data_factory_pipeline" "pl_ingest_ecdc" {
  name            = "pl_ingest_ecdc_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1
  folder          = "Ingestion"
  activities_json = data.template_file.pipelines-ecdc.template
}

