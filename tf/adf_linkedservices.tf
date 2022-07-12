resource "azurerm_data_factory" "covid-reporting-df" {
  name                = "covrepdf${local.my_name}"
  location            = azurerm_resource_group.covid-reporting-rg.location
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
}

#Create a custom linked service to the HTTP URL
resource "azurerm_data_factory_linked_custom_service" "adf-link-source-covid" {
  name            = "ls_http_ecdc_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  type            = "HttpServer"

  parameters = {
    sourceBaseURL : ""
  }

  type_properties_json = <<JSON
{
    "url": "@linkedService().sourceBaseURL",
    "enableServerCertificateValidation": true,
    "authenticationType": "Anonymous"
}
JSON

  annotations = []

}

#Link adf to the source (azure blob storage)
resource "azurerm_data_factory_linked_service_azure_blob_storage" "adf-link-source" {
  name              = "ls_ablobs_covrep${local.my_name}"
  data_factory_id   = azurerm_data_factory.covid-reporting-df.id
  connection_string = azurerm_storage_account.covid-reporting-sa.primary_connection_string
}

#Link adf to the processed data within Azure blob storage using SAS URi
resource "azurerm_data_factory_linked_service_azure_blob_storage" "ls_processed_covidrep" {
  name            = "ls_sa_processed_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  sas_uri         = "https://covrepsamoein.blob.core.windows.net/?sv=2021-06-08&ss=bfqt&srt=sco&sp=rwdlacupitfx&se=2023-01-01T07:24:06Z&st=2022-06-30T22:24:06Z&spr=https&sig=%2FFV0tmyUtRGBxZHT%2FmB22SMLu1%2FPro0Ht3S0NIvrRqs%3D"
}


#Lind adf to the target (dlg2)
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "adf-link-target" {
  name                = "ls_adls_covrep${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  url                 = "https://${azurerm_storage_account.covid-reporting-sa-dl.name}.dfs.core.windows.net"
  storage_account_key = azurerm_storage_account.covid-reporting-sa-dl.primary_access_key
}

#Create a linked service connecting ADF to ADB
resource "azurerm_data_factory_linked_service_azure_databricks" "ls-db-adf" {
  name                = "ls_db_covid_${local.my_name}"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  description         = "ADB Linked Service via MSI"
  adb_domain          = "https://${azurerm_databricks_workspace.covid-rp-databricks.workspace_url}"
  existing_cluster_id = databricks_cluster.Databricks_cluster.id
  access_token        = "dapif7ccc464b6dd2577615f537d29bcf827-3"#var.db_access_token
}

#Create a dataset linking Azure data factory to snowflake 
resource "azurerm_data_factory_linked_service_snowflake" "ls_snowflake" {
  name              = "copy_data_snowflake_${local.my_name}"
  data_factory_id   = azurerm_data_factory.covid-reporting-df.id
  connection_string = "jdbc:snowflake://${var.Snowflake_account_name}.snowflakecomputing.com/?user=${var.snowflake_username}&db=AZURE_COVID_PROJECT&warehouse=COMPUTE_WH&role=ACCOUNTADMIN"
}

