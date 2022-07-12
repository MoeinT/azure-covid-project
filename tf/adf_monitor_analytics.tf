#########################################Creating a budget alert for our resource group
resource "azurerm_monitor_action_group" "action-monitor" {
  name                = "action-monitor-${local.my_name}"
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
  short_name          = "cost-alert"

  dynamic "email_receiver" {
    for_each = local.email_receiver

    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }
}

#Create a cost alert
resource "azurerm_consumption_budget_resource_group" "consumption-budget" {
  name              = "consumption-budget-${local.my_name}"
  resource_group_id = azurerm_resource_group.covid-reporting-rg.id

  amount     = 25
  time_grain = "Quarterly"

  time_period {
    start_date = "2022-06-01T00:00:00Z"
  }

  #if the usage is 80 % of the forecasted amount, send an alert
  notification {
    enabled        = true
    threshold      = 80.0
    operator       = "EqualTo"
    threshold_type = "Forecasted"

    contact_groups = [
      azurerm_monitor_action_group.action-monitor.id,
    ]

    contact_emails = [
      "moin.torabi@gmail.com",
      "mohammadmoein.torabi@grenoble-inp.org",
    ]

    contact_roles = [
      "Owner",
    ]
  }

}

#########################################Creating a pipeline failure alert in Azure Data Factory
resource "azurerm_monitor_action_group" "covid-support-project" {
  name                = "covid-support-project"
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
  short_name          = "covidsupp"

  email_receiver {
    name          = "NewActionEmail"
    email_address = "moin.torabi@gmail.com"
  }
}

resource "azurerm_monitor_metric_alert" "monitor_adf_pipeline_runs" {
  name                = "al_pl_failure"
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
  scopes              = [azurerm_data_factory.covid-reporting-df.id]
  description         = "Create a chart for the total number of success pipeline runs within ADF"
  window_size         = "PT1M"
  frequency           = "PT1M"
  severity            = 0
  auto_mitigate       = false

  criteria {
    metric_namespace = "Microsoft.DataFactory/factories"
    metric_name      = "PipelineFailedRuns"
    aggregation      = "Total"
    operator         = "GreaterThanOrEqual"
    threshold        = 1

    dynamic "dimension" {
      for_each = local.dimensions

      content {
        name     = dimension.value.name
        operator = dimension.value.operator
        values   = dimension.value.values
      }
    }

  }
  action {
    action_group_id = azurerm_monitor_action_group.covid-support-project.id
  }
}

#########################################Azure siagnostic setting sending adf logs in the following locations

#Create a log analytics workspace
resource "azurerm_log_analytics_workspace" "adf_log_analytics_ws" {
  name                = "adf-log-analytics-ws-${local.my_name}"
  location            = azurerm_resource_group.covid-reporting-rg.location
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

#Store log analytics into a blob storage and a log analytics workspace
resource "azurerm_monitor_diagnostic_setting" "adf_metrics" {
  name                           = "azure data factory metrics"
  target_resource_id             = azurerm_data_factory.covid-reporting-df.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.adf_log_analytics_ws.id
  storage_account_id             = azurerm_storage_account.covid-reporting-sa-dl.id
  log_analytics_destination_type = "Dedicated"

  dynamic "log" {
    for_each = local.adf_log
    content {
      category = log.value.category
      enabled  = log.value.enabled
      retention_policy {
        enabled = true
        days    = 6
      }
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = 1
    }
  }
}