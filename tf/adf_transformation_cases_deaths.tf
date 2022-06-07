#Create a container holding the lookup file for the cases_death dataset: 
resource "azurerm_storage_data_lake_gen2_filesystem" "file-system-lookup" {
  name               = "lookups"
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

#Create a dataset that points towards the lookup file
resource "azurerm_data_factory_dataset_delimited_text" "ds-lookup" {
  name                = "df_country_lookup_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-lookup.name
    #path        = ""
    filename = local.lookup_file
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = ","
  row_delimiter       = "\n"
}

#Create a new dataset for the processed cases and deaths dataset

resource "azurerm_data_factory_dataset_delimited_text" "ds-cases-deaths-processed" {
  name                = "df_processed_cases_deaths_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-processed.name
    path        = "ecdc/cases_death"
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = ","
  row_delimiter       = "\n"
}

#Create a pipeline that would trigger the transformation of cases_deaths data
data "template_file" "pipelines-dataflow-cases-deaths" {
  template = file(local.arm_pipeline_dataflow_cases_deaths)
}

resource "azurerm_data_factory_pipeline" "pl_dataflow_cases_deaths" {
  name            = "pl_process_cases_deaths_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1
  activities_json = data.template_file.pipelines-dataflow-cases-deaths.template
}