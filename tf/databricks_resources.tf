resource "azurerm_key_vault" "KeyVault" {
  name                        = "KeyVault-${local.my_name}"
  location                    = azurerm_resource_group.covid-reporting-rg.location
  resource_group_name         = azurerm_resource_group.covid-reporting-rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7

  sku_name = "standard"


  dynamic "access_policy" {
    for_each = local.access_policy
    content {
      tenant_id           = access_policy.value.tenant_id
      object_id           = access_policy.value.object_id
      secret_permissions  = access_policy.value.secret_permissions
      key_permissions     = ["Get", ]
      storage_permissions = ["Get", ]
    }
  }
}

resource "azurerm_databricks_workspace" "covid-rp-databricks" {
  name                          = "covid-reporting-databricks-${local.my_name}"
  resource_group_name           = azurerm_resource_group.covid-reporting-rg.name
  location                      = azurerm_resource_group.covid-reporting-rg.location
  sku                           = "premium"
  public_network_access_enabled = true
}

#We need to reference an existing workspace in our Databricks provider
provider "databricks" {
  host  = azurerm_databricks_workspace.covid-rp-databricks.workspace_url
  token = "dapif7ccc464b6dd2577615f537d29bcf827-3"
}

#Spark version
data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

output "workspace_url" {
  value = azurerm_databricks_workspace.covid-rp-databricks.workspace_url
}

output "workspace_id" {
  value = azurerm_databricks_workspace.covid-rp-databricks.id
}


#Databricks cluster (permissions)
resource "databricks_cluster" "Databricks_cluster" {
  cluster_name            = "covid-reporting-cluster-${local.my_name}"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = "Standard_DS3_v2"
  autotermination_minutes = 20
  autoscale {
    min_workers = 1
    max_workers = 3
  }
}

