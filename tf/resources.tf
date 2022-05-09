resource "azurerm_data_factory" "covid-reporting-df" {
  name                = "covrepdfmoein"
  location            = azurerm_resource_group.covid-reporting-rg.location
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
}

resource "azurerm_storage_account" "covid-reporting-sa" {
  name                     = "covrepsamoein"
  resource_group_name      = azurerm_resource_group.covid-reporting-rg.name
  location                 = azurerm_resource_group.covid-reporting-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# resource "azurerm_storage_container" "blob-container-population" {
#   name                  = "blobmoein"
#   storage_account_name  = azurerm_storage_account.covid-reporting-sa.name
#   container_access_type = "blob"
# }

#To use this sa for dlgen2, we need to configure a hierarchical namespace
resource "azurerm_storage_account" "covid-reporting-sa-dl" {
  name                     = "covrepsadlmoein"
  resource_group_name      = azurerm_resource_group.covid-reporting-rg.name
  location                 = azurerm_resource_group.covid-reporting-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = "true"
}







