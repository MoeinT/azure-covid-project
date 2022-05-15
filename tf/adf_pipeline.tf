locals {
  arm_pipeline_template = "templates/adf_pipeline.json"
}

data "template_file" "pipeline" {
  template = file(local.arm_pipeline_template)
}


# Create a pipeline passing a list of the services you're using in your pipeline
resource "azurerm_data_factory_pipeline" "pl_ingest_population" {
  name            = "pl_ingest_pop_moein"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  concurrency     = 1
  activities_json = data.template_file.pipeline.template

  parameters = {
    EmailTo : "moin.torabi@gmail.com"
    Message : "There's an error regarding the number of columns!"
    ActivityName : "Copying Data"
  }

}