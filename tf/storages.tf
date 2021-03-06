#Source sa
resource "azurerm_storage_account" "covid-reporting-sa" {
  name                     = "covrepsa${local.my_name}"
  resource_group_name      = azurerm_resource_group.covid-reporting-rg.name
  location                 = azurerm_resource_group.covid-reporting-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#Container holding the population data (source .tsv.gz)
resource "azurerm_storage_container" "blob-container-population" {
  name                  = "population${local.my_name}source"
  storage_account_name  = azurerm_storage_account.covid-reporting-sa.name
  container_access_type = "private"
}

#To use this sa for dlgen2, we need to configure a hierarchical namespace
#Target sa
resource "azurerm_storage_account" "covid-reporting-sa-dl" {
  name                     = "covrepsadl${local.my_name}"
  resource_group_name      = azurerm_resource_group.covid-reporting-rg.name
  location                 = azurerm_resource_group.covid-reporting-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = "true"
}

#file-system-population
#The container holding the raw data
resource "azurerm_storage_data_lake_gen2_filesystem" "file-system-raw" {
  name               = "raw${local.my_name}"
  storage_account_id = azurerm_storage_account.covid-reporting-sa-dl.id
}

#Create a container within the dlgen2 for the transformed data
resource "azurerm_storage_data_lake_gen2_filesystem" "file-system-processed" {
  name               = "processed${local.my_name}"
  storage_account_id = azurerm_storage_account.covid-reporting-sa-dl.id
}

#Create a container within the dlgen2 for the transformed data from Python
resource "azurerm_storage_data_lake_gen2_filesystem" "file-system-processed-python" {
  name               = "processed${local.my_name}python"
  storage_account_id = azurerm_storage_account.covid-reporting-sa-dl.id
}

#Create a container holding the lookup file for the join transformations: 
resource "azurerm_storage_data_lake_gen2_filesystem" "file-system-lookup" {
  name               = "lookups"
  storage_account_id = azurerm_storage_account.covid-reporting-sa-dl.id
}

#Create a container within the storage account hoding the processed data 
resource "azurerm_storage_container" "processed-data" {
  name                  = "processed${local.my_name}"
  storage_account_name  = azurerm_storage_account.covid-reporting-sa.name
  container_access_type = "private"
}