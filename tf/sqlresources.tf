#Creating an Azure SQL server
resource "azurerm_mssql_server" "covid-srv" {
  name                         = "covid-mssql-server"
  resource_group_name          = azurerm_resource_group.covid-reporting-rg.name
  location                     = azurerm_resource_group.covid-reporting-rg.location
  version                      = "12.0"
  administrator_login          = var.mssql_admin_login
  administrator_login_password = var.mssql_admin_password
}

#Firewall rules allowing access to Azure Services
resource "azurerm_mssql_firewall_rule" "firewall-sql-server" {
  name             = "access_azure_services"
  server_id        = azurerm_mssql_server.covid-srv.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}


#Creating an Azure SQL database
resource "azurerm_mssql_database" "covid-db" {
  name      = "covid-db"
  server_id = azurerm_mssql_server.covid-srv.id
}