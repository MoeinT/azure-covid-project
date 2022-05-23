#Create a custom linked service to the HTTP URL
resource "azurerm_data_factory_linked_custom_service" "adf-link-source-covid" {
  name            = "ls_https_ecdc_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  type            = "HttpServer"

  type_properties_json = <<JSON
{
    "url": "${local.base_url_ecdc}",
    "enableServerCertificateValidation": true,
    "authenticationType": "Anonymous"
}
JSON

  annotations = []

}

resource "azurerm_data_factory_dataset_delimited_text" "ds-source-ecdc" {
  name                = "ds_ecdc_raw_csv_http_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_custom_service.adf-link-source-covid.name

  #Parameterize the relative url
  parameters = {
    relativeURL = ""
  }


  http_server_location {
    relative_url         = "@dataset().relativeURL"
    dynamic_path_enabled = "true"
    path                 = "covid19/nationalcasedeath/csv/"
    filename             = "data.csv"
  }

  column_delimiter    = ","
  row_delimiter       = "\n"
  encoding            = "UTF-8"
  first_row_as_header = true
}

#Create a dataset within dlgen2 to hold the cases and death data
resource "azurerm_data_factory_dataset_delimited_text" "ds-target-ecdc" {
  name                = "ds_ecdc_raw_csv_http_dl${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  #Parameterize the filename
  parameters = {
    fileName = ""
  }

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-population.name
    path        = "ecdc"
    filename    = "@dataset().fileName"
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = "\t"
  row_delimiter       = "\n"
}

#Create a pipeline to ingest cases and death data

data "template_file" "pipelines-ecdc" {
  template = file(local.arm_pipeline_ecdc_template)
}

resource "azurerm_data_factory_pipeline" "pl_ingest_cases_death" {
  name            = "pl_ingest_ecdc_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1

  parameters = {
    sourceRelativeURL : ""
    sinkFileName : ""

  }

  activities_json = data.template_file.pipelines-ecdc.template
}

