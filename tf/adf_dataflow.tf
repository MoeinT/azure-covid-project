#Create a container holding the lookup file for the cases_death dataset: 

resource "azurerm_storage_data_lake_gen2_filesystem" "file-system-lookup" {
  name               = "lookup_cases_death${local.my_name}"
  storage_account_id = azurerm_storage_account.covid-reporting-sa-dl.id
}