#Create a logic app for custom email
resource "azurerm_logic_app_workflow" "logicapp" {
  name                = "send-custom-email"
  location            = azurerm_resource_group.covid-reporting-rg.location
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
}

data "template_file" "workflow" {
  template = file(local.arm_logicapp_template)
}

#Deploy the ARM template workflow
resource "azurerm_resource_group_template_deployment" "workflow" {
  name                = "deploy-template"
  depends_on          = [azurerm_logic_app_workflow.logicapp]
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
  template_content    = data.template_file.workflow.template
  deployment_mode     = "Incremental"
}