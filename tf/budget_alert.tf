resource "azurerm_monitor_action_group" "action-monitor" {
  name                = "action-monitor-${local.my_name}"
  resource_group_name = azurerm_resource_group.covid-reporting-rg.name
  short_name          = "cost-alert"

  email_receiver {
    name                    = "Sendtoadmin1"
    email_address           = "moin.torabi@gmail.com"
    use_common_alert_schema = true
  }

  email_receiver {
    name                    = "Sendtoadmin2"
    email_address           = "mohammadmoein.torabi@grenoble-inp.org"
    use_common_alert_schema = true
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