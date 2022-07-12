# #Create a dataset linking adf to the processed hospitals admissions daily data
resource "azurerm_data_factory_dataset_delimited_text" "ds_processed_hospitals_daily" {
  name                = "ds_processed_hospitals_daily_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.ls_processed_covidrep.name
  folder              = "processed"
  azure_blob_storage_location {
    container = azurerm_storage_container.processed-data.name
    path      = "ecdc/hospital_admissions_daily"
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = ","
  row_delimiter       = "\n"
}

#Create a dataset linking Azure data factory to the hospitals admissions daily data in Snowflake
resource "azurerm_data_factory_dataset_snowflake" "ds_hospital_admissions_daily_snowflake" {
  name                = "ds_hospital_admissions_daily_snowflake_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_snowflake.ls_snowflake.name
  folder              = "snowflake"
  schema_name         = "PUBLIC"
  table_name          = "HOSPITALADMISSIONSDAILY"
}


#Create a dataset linking adf to the processed hospitals admissions weekly data
resource "azurerm_data_factory_dataset_delimited_text" "ds_processed_hospitals_weekly" {
  name                = "ds_processed_hospitals_weekly_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.ls_processed_covidrep.name
  folder              = "processed"
  azure_blob_storage_location {
    container = azurerm_storage_container.processed-data.name
    path      = "ecdc/hospital_admissions_weekly"
  }
  first_row_as_header = true
  compression_level   = "Optimal"
  column_delimiter    = ","
  row_delimiter       = "\n"
}

#Create a dataset linking Azure data factory to the hospitals admissions weekly data in Snowflake
resource "azurerm_data_factory_dataset_snowflake" "ds_hospital_admissions_weekly_snowflake" {
  name                = "ds_hospital_admissions_weekly_snowflake_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  linked_service_name = azurerm_data_factory_linked_service_snowflake.ls_snowflake.name
  folder              = "snowflake"
  schema_name         = "PUBLIC"
  table_name          = "HOSPITALADMISSIONSWEEKLY"
}


resource "databricks_notebook" "hospital_notebook" {
  source = local.hospital_transformation_path
  path   = "/Covid/transformations/hospital_transformation"
}

data "template_file" "pipelines-tansf-hospitals" {
  template = file(local.arm_pipeline_hospitals_trans)
}

# Create a pipeline to run the notebook we deployed above
resource "azurerm_data_factory_pipeline" "pl_adb_hospital_data" {
  name            = "pl_adb_hospitals_data_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1
  folder          = "Process_copy"
  activities_json = data.template_file.pipelines-tansf-hospitals.template
}