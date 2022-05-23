#Create a custom linked service to the HTTP URL
resource "azurerm_data_factory_linked_custom_service" "adf-link-source-covid" {
  name            = "ls_https_ecdc_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  type            = "HttpServer"

  type_properties_json = <<JSON
{
    "url": "https://opendata.ecdc.europa.eu",

    "enableServerCertificateValidation": true,

    "authenticationType": "Anonymous"
}
JSON

  annotations = []

}

resource "azurerm_data_factory_dataset_delimited_text" "ds-source-cases-death" {
  name                = "ds_cases_death_raw_csv_http_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_custom_service.adf-link-source-covid.name

  http_server_location {
    relative_url = "covid19/nationalcasedeath/csv/data.csv"
    path         = "covid19/nationalcasedeath/csv/"
    filename     = "data.csv"
  }

  column_delimiter    = ","
  row_delimiter       = "\n"
  encoding            = "UTF-8"
  first_row_as_header = true
}

#Create a dataset within dlgen2 to hold the cases and death data
resource "azurerm_data_factory_dataset_delimited_text" "ds-target-cases-death" {
  name                = "ds_cases_death_raw_csv_http_dl${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-population.name
    path        = "ecdc"
    filename    = local.target_cases
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = "\t"
  row_delimiter       = "\n"
}

#Create a pipeline to ingest cases and death data

data "template_file" "pipelines-cases-death" {
  template = file(local.arm_pipeline_cases_death_template)
}

resource "azurerm_data_factory_pipeline" "pl_ingest_cases_death" {
  name            = "pl_ingest_cases_death_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1
  activities_json = data.template_file.pipelines-cases-death.template
}