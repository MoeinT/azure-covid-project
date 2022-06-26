#Create a managed identity to give access to our data lake gen2
resource "azurerm_user_assigned_identity" "covid-user-assigned-identity" {
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
  location            = azurerm_resource_group.covid-reporting-rg.location

  name = "covid-user-assigned-identity-${local.my_name}"
}

#Create a dataset for raw tests data
resource "azurerm_data_factory_dataset_delimited_text" "ds-tests-raw" {
  name                = "ds_raw_covid_tests_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-population.name
    path        = "ecdc"
    filename    = local.tests
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = "\t"
  row_delimiter       = "\n"
}

#Create a dataset for processed tests data
resource "azurerm_data_factory_dataset_delimited_text" "dds-tests-processed" {
  name                = "ds_processed_covid_tests_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-processed.name
    path        = "ecdc/covidtests"
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = ","
  row_delimiter       = "\n"
}

data "template_file" "pipelines-dataflow-tests" {
  template = file(local.arm_pipeline_dataflow_tests)
}

resource "azurerm_data_factory_pipeline" "pl_dataflow_tests" {
  name            = "pl_process_covidtests_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1
  activities_json = data.template_file.pipelines-dataflow-tests.template
}



