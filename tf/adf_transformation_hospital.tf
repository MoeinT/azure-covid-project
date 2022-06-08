#Create a dataset poitning towards the hospitals admissions raw data
resource "azurerm_data_factory_dataset_delimited_text" "ds-hospitals-admissions" {
  name                = "ds_raw_hospital_admissions_${local.my_name}"
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

#Dataset to store the hospital admissions data on a weekly basis
resource "azurerm_data_factory_dataset_delimited_text" "ds-hospitals-admissions-processed-weekly" {
  name                = "ds_processed_hospital_admissions_weekly${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-processed.name
    path        = "ecdc/hospital_admissions_weekly"
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = ","
  row_delimiter       = "\n"
}

#Dataset to store the hospital admissions data on a daily basis
resource "azurerm_data_factory_dataset_delimited_text" "ds-hospitals-admissions-processed-daily" {
  name                = "ds_processed_hospital_admissions_daily${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-processed.name
    path        = "ecdc/hospital_admissions_daily"
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = ","
  row_delimiter       = "\n"
}


#Create a dataset that points towards the Dim_Date lookup file
resource "azurerm_data_factory_dataset_delimited_text" "ds-lookup-dim-date" {
  name                = "ds_dim_date_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.adf-link-target.name

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.file-system-lookup.name
    #path        = ""
    filename = local.lookup_file_dim_date
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = ","
  row_delimiter       = "\n"
}

data "template_file" "pipelines-dataflow-hospitals-admissions" {
  template = file(local.arm_pipeline_dataflow_hospitals)
}

resource "azurerm_data_factory_pipeline" "pl_dataflow_hospital_admissions" {
  name            = "pl_process_hospital_admissions_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1
  activities_json = data.template_file.pipelines-dataflow-hospitals-admissions.template
}