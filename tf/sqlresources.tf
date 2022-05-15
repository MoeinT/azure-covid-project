resource "azurerm_mssql_server" "covid-srv" {
  name                          = "mssql${local.my_name}"
  resource_group_name           = azurerm_resource_group.covid-reporting-rg.name
  location                      = azurerm_resource_group.covid-reporting-rg.location
  version                       = "12.0"
  administrator_login           = var.mssql_login
  administrator_login_password  = var.mssql_password
  public_network_access_enabled = true
}

#Firewall rules allowing access to Azure Services
resource "azurerm_mssql_firewall_rule" "firewall-sql-server" {
  name             = "access_azure_services${local.my_name}"
  server_id        = azurerm_mssql_server.covid-srv.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"

}

resource "azurerm_mssql_database" "covid-db" {
  name      = "covid-db${local.my_name}"
  server_id = azurerm_mssql_server.covid-srv.id
}