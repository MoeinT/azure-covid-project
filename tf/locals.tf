locals {
  my_name                          = "moein"
  arm_logicapp_template            = "templates/logic_app_template.json"
  arm_pipeline_population_template = "templates/adf_pipeline_population.json"
  arm_pipeline_ecdc_template       = "templates/adf_pipeline_ecdc_template.json"
  source_blob_name                 = "population_by_age.tsv.gz"
  target_blob_name                 = "population_by_age.tsv"
  config_filename                  = "ecdc_file_list.json"
}
