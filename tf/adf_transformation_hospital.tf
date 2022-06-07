#Create a dataset poitning towards the hospitals admissions raw data
resource "azurerm_data_factory_dataset_delimited_text" "ds-hospitals-admissions" {
  name                = "df_raw_hospital_admissions_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-population.name
    path        = "ecdc"
    filename    = local.hospital_admissions
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = "\t"
  row_delimiter       = "\n"
}

resource "azurerm_data_factory_dataset_delimited_text" "ds-hospitals-admissions-processed" {
  name                = "df_processed_hospital_admissions_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-processed.name
    path        = "ecdc/hospital_admissions"
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = ","
  row_delimiter       = "\n"
}


# data "template_file" "pipelines-dataflow-hospitals-admissions" {
#   template = file(local.arm_pipeline_dataflow_hospitals)
# }

# resource "azurerm_data_factory_pipeline" "pl_dataflow_cases_deaths" {
#   name            = "pl_process_cases_deaths_${local.my_name}"
#   data_factory_id = azurerm_data_factory.covid-reporting-df.id
#   concurrency     = 1
#   activities_json = data.template_file.pipelines-dataflow-hospitals-admissions.template
# }