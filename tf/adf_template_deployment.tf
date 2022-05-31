#Provision as Azure Data Factory with all its components using an ARM Template
resource "azurerm_data_factory" "covid-reporting-df_template" {
  name                = "covrepdf${local.my_name}1"
  location            = azurerm_resource_group.covid-reporting-rg.location
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
}

data "template_file" "adf-template" {
  template = file(local.arm_adf_template)
}


resource "azurerm_resource_group_template_deployment" "adf-template-deployment" {
  name                = "adf_template_${local.my_name}"
  depends_on          = [azurerm_data_factory.covid-reporting-df_template]
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
  template_content    = data.template_file.adf-template.template
  deployment_mode     = "Incremental"
}