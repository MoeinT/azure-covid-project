terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

#Create a data object
data "azurerm_client_config" "current" {
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

#Create a resource group for our resources 
resource "azurerm_resource_group" "covid-reporting-rg" {
  name     = "covidreportingrg"
  location = "West Europe"
}

