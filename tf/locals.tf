locals {
  my_name               = "moein"
  arm_logicapp_template = "templates/logic_app_template.json"
  arm_pipeline_template = "templates/adf_pipeline.json"
  source_blob_name      = "population_by_age.tsv.gz"
  target_blob_name      = "population_by_age.tsv"
  target_cases          = "cases_deaths_csv"
}
