resource "azurerm_data_factory" "covid-reporting-df" {
  name                = "covrepdfmoein"
  location            = azurerm_resource_group.covid-reporting-rg.location
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
}

#Link adf to the source (azure blob storage)
resource "azurerm_data_factory_linked_service_azure_blob_storage" "adf-link-source" {
  name              = "ls_ablobs_covrepmoein"
  data_factory_id   = azurerm_data_factory.covid-reporting-df.id
  connection_string = azurerm_storage_account.covid-reporting-sa.primary_connection_string
}

#Lind adf to the target (dlg2)
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "adf-link-target" {
  name                = "ls_adls_covrepmoein"
  data_factory_id     = azurerm_data_factory.covid-reporting-df.id
  url                 = "https://datalakestoragegen2"
  storage_account_key = azurerm_storage_account.covid-reporting-sa-dl.primary_access_key
}
