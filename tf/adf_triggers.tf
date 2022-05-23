#Create a scheduling trigger for the above pipeline and pass in the parameters at runtime

resource "azurerm_data_factory_trigger_schedule" "tr-ingest-hospital" {
  name            = "tr_ingest_hospital_admissions_${local.my_name}"
  data_factory_id = azurerm_data_factory.covid-reporting-df.id
  pipeline_name   = azurerm_data_factory_pipeline.pl_ingest_cases_death.name

  start_time = "2022-05-23T23:25:00.00Z"

  #The ecdc data gets updated every week
  interval  = 1
  frequency = "Week"
  activated = "true"

  pipeline_parameters = {
    sourceRelativeURL = "covid19/hospitalicuadmissionrates/csv/data.csv"
    sinkFileName      = "hospitals_admissions_csv"

  }
}