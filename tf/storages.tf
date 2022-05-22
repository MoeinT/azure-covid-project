#Source sa
resource "azurerm_storage_account" "covid-reporting-sa" {
  name                     = "covrepsa${local.my_name}"
  resource_group_name      = azurerm_resource_group.covid-reporting-rg.name
  location                 = azurerm_resource_group.covid-reporting-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#The container holding the population data (source .tsv.gz)
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

#The container holding the population data (target .tsv )
resource "azurerm_storage_data_lake_gen2_filesystem" "file-system-population" {
  name               = "raw${local.my_name}"
  storage_account_id = azurerm_storage_account.covid-reporting-sa-dl.id
}







