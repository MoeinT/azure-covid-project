#Create an azure data factory within our resource group
resource "azurerm_data_factory" "covid-reporting-df" {
  name                = "covidreportingdf"
  location            = azurerm_resource_group.covid-reporting-rg.location
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
}

#Create a storage account within our resource group
resource "azurerm_storage_account" "covid-reporting-sa" {
  name                     = "covidreportingsa"
  resource_group_name      = azurerm_resource_group.covid-reporting-rg.name
  location                 = azurerm_resource_group.covid-reporting-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#create a blob storage container within the above storage account 
resource "azurerm_storage_container" "blob-container-population" {
  name                  = "blobcontainer22population"
  storage_account_name  = azurerm_storage_account.covid-reporting-sa.name
  container_access_type = "blob"
}

#To use this sc for dlgen2, we need to configure a hierarchical namespace
resource "azurerm_storage_account" "covid-reporting-sa-dl" {
  name                     = "covidreportingsa22dl"
  resource_group_name      = azurerm_resource_group.covid-reporting-rg.name
  location                 = azurerm_resource_group.covid-reporting-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = "true"
}








