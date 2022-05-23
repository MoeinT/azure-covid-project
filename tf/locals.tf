locals {
  my_name                           = "moein"
  arm_logicapp_template             = "templates/logic_app_template.json"
  arm_pipeline_population_template  = "templates/adf_pipeline_population.json"
  arm_pipeline_cases_death_template = "templates/adf_pipeline_cases_death_template.json"
  source_blob_name                  = "population_by_age.tsv.gz"
  target_blob_name                  = "population_by_age.tsv"
  target_cases                      = "cases_deaths_csv"
}
