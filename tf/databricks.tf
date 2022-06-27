# output "debug_object_id" {
#   value = data.azurerm_client_config.current.object_id
# }

# resource "azurerm_key_vault" "KeyVault" {
#   name                        = "KeyVault-${local.my_name}"
#   location                    = azurerm_resource_group.covid-reporting-rg.location
#   resource_group_name         = azurerm_resource_group.covid-reporting-rg.name
#   enabled_for_disk_encryption = true
#   tenant_id                   = data.azurerm_client_config.current.tenant_id
#   soft_delete_retention_days  = 7

#   sku_name = "standard"

#   access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = "4f0124f7-b2e3-4b1f-b4ab-d522c78d0ff9"

#     key_permissions = [
#       "Get",
#     ]

#     secret_permissions = [
#       "Get", "List"
#     ]

#     storage_permissions = [
#       "Get",
#     ]
#   }

#   access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = "ed62eb30-0e44-4e66-8d03-42850b52192f"

#     key_permissions = [
#       "Get",
#     ]

#     secret_permissions = [
#       "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
#     ]

#     storage_permissions = [
#       "Get",
#     ]
#   }
# }




# resource "azurerm_databricks_workspace" "covid-rp-databricks" {
#   name                          = "covid-reporting-databricks-${local.my_name}"
#   resource_group_name           = azurerm_resource_group.covid-reporting-rg.name
#   location                      = azurerm_resource_group.covid-reporting-rg.location
#   sku                           = "premium"
#   public_network_access_enabled = true
# }

# #We need to reference an existing workspace in our Databricks provider
# provider "databricks" {
#   host = azurerm_databricks_workspace.covid-rp-databricks.workspace_url
# }

# #Spark version
# data "databricks_spark_version" "latest_lts" {
#   long_term_support = true
# }

# output "workspace_id" {
#   value = azurerm_databricks_workspace.covid-rp-databricks.workspace_url
# }

# #Databricks cluster (permissions)
# resource "databricks_cluster" "Databricks_cluster" {
#   cluster_name            = "covid-reporting-cluster-${local.my_name}"
#   spark_version           = data.databricks_spark_version.latest_lts.id
#   node_type_id            = "Standard_DS3_v2"
#   autotermination_minutes = 20
#   autoscale {
#     min_workers = 1
#     max_workers = 3
#   }
# }

# resource "databricks_notebook" "population_notebook" {
#   source = "../scripts/population_transformation.py"
#   path   = "/Covid/transformations/population_transformation"
# }