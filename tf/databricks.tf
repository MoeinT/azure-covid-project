resource "azurerm_databricks_workspace" "covid-rp-databricks" {
  name                = "covid-reporting-databricks-${local.my_name}"
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
  location            = azurerm_resource_group.covid-reporting-rg.location
  sku                 = "standard"
}

#We need to reference an existing workspace in our Databricks provider
provider "databricks" {
  host = azurerm_databricks_workspace.covid-rp-databricks.workspace_url
}

#Spark version
data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

#Databricks cluster
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

