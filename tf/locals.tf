locals {
  my_name                            = "moein"
  arm_logicapp_template              = "templates/logic_app_custom_email_notification.json"
  arm_pipeline_population_ingest     = "templates/adf_pipeline_ingest_pop.json"
  arm_pipeline_population_trans      = "templates/databricks_snowflake/adf_pipeline_db_snowflake_pop.json"
  arm_pipeline_covidtests_trans      = "templates/databricks_snowflake/adf_pipeline_db_snowflake_covidtests.json"
  arm_pipeline_hospitals_trans       = "templates/databricks_snowflake/adf_pipeline_db_snowflake_hospitals.json"
  arm_pipeline_casesdeaths_trans     = "templates/databricks_snowflake/adf_pipeline_db_snowflake_casesdeaths.json"
  arm_pipeline_execution_population  = "templates/executions/pl_executate_population_pipeline.json"
  arm_pipeline_execution_ecdc_trans  = "templates/executions/pl_executate_ecdc_trans_pipeline.json"
  arm_pipeline_ecdc_template         = "templates/adf_pipeline_ingest_ecdc.json"
  source_blob_name                   = "population_by_age.tsv.gz"
  target_blob_name                   = "population_by_age.tsv"
  config_filename                    = "ecdc_file_list.json"
  cases_death                        = "cases_deaths/cases_deaths.csv"
  country_response                   = "country_response.csv"
  hospital_admissions                = "hospital_admissions/hospital_admissions.csv"
  tests                              = "testing/testing.csv"
  testing                            = "testing.csv"
  lookup_file                        = "country_lookup/country_lookup.csv"
  lookup_file_dim_date               = "dim_date/dim_date.csv"
  arm_pipeline_dataflow_cases_deaths = "templates/adf_pipeline_transform_cases_deaths.json"
  arm_pipeline_dataflow_hospitals    = "templates/adf_pipeline_transform_hospital.json"
  arm_pl_dataflow_hospitals          = "templates/adf_pipeline_transform_hospital.json"
  population_transformation_path     = "../scripts/population_transformation.py"
  covidtests_transformation_path     = "../scripts/covidtests_transformations.py"
  hospital_transformation_path       = "../scripts/hospital_transformations.py"
  casesdeaths_transformation_path    = "../scripts/casesdeaths_transformations.py"
  access_policy = [
    {
      tenant_id          = data.azurerm_client_config.current.tenant_id
      object_id          = "4f0124f7-b2e3-4b1f-b4ab-d522c78d0ff9"
      secret_permissions = ["Get", "List"]
    },
    {
      tenant_id          = data.azurerm_client_config.current.tenant_id
      object_id          = data.azurerm_client_config.current.object_id
      secret_permissions = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
    }
  ]

  email_receiver = [
    {
      name                    = "Sendtoadmin1"
      email_address           = "moin.torabi@gmail.com"
      use_common_alert_schema = true
    },
    {
      name                    = "Sendtoadmin2"
      email_address           = "mohammadmoein.torabi@grenoble-inp.org"
      use_common_alert_schema = true

    }
  ]

  dimensions = [
    {
      name     = "Name"
      operator = "Include"
      values = [azurerm_data_factory_pipeline.pl_execute_population_pipelines.name,
        azurerm_data_factory_pipeline.pl_execute_ecdc_trans_pipelines.name
      ]
    },
    {
      name     = "FailureType"
      operator = "Include"
      values   = ["UserError", "SystemError", "BadGateway"]
    }
  ]

  adf_log = [
    {
      category = "ActivityRuns"
      enabled  = true
    },
    {
      category = "TriggerRuns"
      enabled  = true
    },
    {
      category = "PipelineRuns"
      enabled  = true
    }
  ]

}