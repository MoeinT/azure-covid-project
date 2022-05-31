locals {
  my_name                            = "moein"
  arm_logicapp_template              = "templates/logic_app_custom_email_notification.json"
  arm_pipeline_population_template   = "templates/adf_pipeline_ingest_pop.json"
  arm_pipeline_ecdc_template         = "templates/adf_pipeline_ingest_ecdc.json"
  source_blob_name                   = "population_by_age.tsv.gz"
  target_blob_name                   = "population_by_age.tsv"
  config_filename                    = "ecdc_file_list.json"
  cases_death                        = "cases_deaths.csv"
  country_response                   = "country_response.csv"
  hospital_admissions                = "hospital_admissions.csv"
  testing                            = "testing.csv"
  lookup_file                        = "country_lookup.csv"
  arm_adf_template                   = "templates/adf_arm_template.json"
  arm_pipeline_dataflow_cases_deaths = "templates/adf_pipeline_transform_cases_deaths.json"
}
