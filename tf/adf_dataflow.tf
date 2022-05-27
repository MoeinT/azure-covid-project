#Create a container holding the lookup file for the cases_death dataset: 
resource "azurerm_storage_data_lake_gen2_filesystem" "file-system-lookup" {
  name               = "lookup-casesdeaths"
  storage_account_id = azurerm_storage_account.covid-reporting-sa-dl.id
}

#Create a dataset poitning towards the cases and deaths data
resource "azurerm_data_factory_dataset_delimited_text" "ds-cases-deaths" {
  name                = "df_raw_cases_deaths_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-population.name
    path        = "ecdc"
    filename    = local.cases_death
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = "\t"
  row_delimiter       = "\n"
}



#Create a dataflow for the cases and deaths dataset
# resource "azurerm_data_factory_data_flow" "df-cases-deaths" {
#   name            = "df_transform_cases_deaths_${local.my_name}"
#   data_factory_id = azurerm_data_factory.covid-reporting-df.id

#   source {
#     name = "CasesAndDeathsSource"

#     dataset {
#       name = azurerm_data_factory_dataset_json.example1.name
#     }
#   }

#   sink {
#     name = "sink1"

#     dataset {
#       name = azurerm_data_factory_dataset_json.example2.name
#     }
#   }

#   script = <<EOT
# source(
#   allowSchemaDrift: true, 
#   validateSchema: false, 
#   limit: 100, 
#   ignoreNoFilesFound: false, 
#   documentForm: 'documentPerLine') ~> source1 
# source1 sink(
#   allowSchemaDrift: true, 
#   validateSchema: false, 
#   skipDuplicateMapInputs: true, 
#   skipDuplicateMapOutputs: true) ~> sink1
# EOT
# }