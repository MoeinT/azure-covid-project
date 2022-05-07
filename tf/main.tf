terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate22sa"
    container_name       = "tfstate-container"
    key                  = "terraform.tfstate"
  }
}

data "azurerm_client_config" "current" {
}

provider "azurerm" {
  subscription_id = "1b7f4ea1-c952-4797-ab87-31c4b9078163"
  features {}
}

resource "azurerm_resource_group" "tfstate" {
  name     = "tfstate-rg"
  location = "France Central"
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstate22sa"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate-container"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "blob"
}

resource "azurerm_resource_group" "covid-reporting-rg" {
  name     = "covreprgmoein"
  location = "East Us"
}