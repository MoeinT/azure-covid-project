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


data "azuread_client_config" "current" {

}


data "azurerm_client_config" "current" {
}


data "azurerm_subscription" "current" {
}


provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "tfstate" {
  name     = "tfstate-rg"
  location = "France Central"
}


resource "azuread_application" "gh_actions" {
  display_name = "covid-app"
}



resource "azuread_service_principal" "gh_actions" {
  application_id = azuread_application.gh_actions.application_id
}


resource "azuread_service_principal_password" "gh_actions" {
  service_principal_id = azuread_service_principal.gh_actions.object_id
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

resource "github_actions_secret" "actions_secret" {
  for_each = {
    ARM_CLIENT_ID       = azuread_service_principal.gh_actions.application_id
    ARM_CLIENT_SECRET   = azuread_service_principal_password.gh_actions.value
    ARM_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
    ARM_TENANT_ID       = data.azuread_client_config.current.tenant_id
  }

  secret_name = each.key
  repository  = "azure-covid-project"
}