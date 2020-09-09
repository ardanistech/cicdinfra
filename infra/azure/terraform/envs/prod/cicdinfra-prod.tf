locals {
  tags = {
    workload = "production",
    team     = "cicdinfra",
    env      = "prod"
  }

  app_service_plan_name = "cicdinfra-prod-asp"
}

resource azurerm_resource_group prod {
  name     = "cicdinfra-prod"
  location = module.globals.azure_region
  tags     = local.tags
}

module prod_webapp {
  source = "../../stacks/web-app"

  azure_region = module.globals.azure_region

  resource_group_name = azurerm_resource_group.prod.name

  app_service_tags = local.tags

  app_service_plan = {
    name = local.app_service_plan_name
    tier = "Standard"
    size = "S1"
  }

  app_service_vnet = {
    name        = "cicdinfra-prod-vnet"
    subnet_name = "cicdinfra-prod-sn"
    nsg_name    = "cicdinfra-prod-nsg"
  }

  app_service = {
    name             = "cicdinfra-prod-as"
    hostname         = "app.prod.cicdinfra"
    environment_type = "prod"
    always_on        = true
  }

  app_service_slot = {
    enabled          = true
    name             = "staging"
    environment_type = "prod"
    always_on        = false
  }

  app_service_access_restrictions = []

  postgres = {
    name                 = "cicdinfra-prod-pgs"
    admin_login          = var.postgres_admin_login
    admin_password       = var.postgres_admin_password
    sku_name             = "GP_Gen5_2"
    virtual_network_rule = true
  }

  storage_account_name = "cicdinfraprodsa"
}

resource azurerm_monitor_autoscale_setting prod {
  name                = "${local.app_service_plan_name}-Autoscale"
  location            = module.globals.azure_region
  resource_group_name = azurerm_resource_group.prod.name
  target_resource_id  = module.prod_webapp.app_service_plan_id
  enabled             = true
  profile {
    name = "Scale Out/In"
    capacity {
      default = "1"
      minimum = "1"
      maximum = "3"
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = module.prod_webapp.app_service_plan_id
        operator           = "GreaterThan"
        statistic          = "Average"
        threshold          = "80.0"
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT10M"
      }
      scale_action {
        cooldown  = "PT5M"
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = module.prod_webapp.app_service_plan_id
        operator           = "LessThan"
        statistic          = "Average"
        threshold          = "60.0"
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT10M"
      }
      scale_action {
        cooldown  = "PT5M"
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "MemoryPercentage"
        metric_resource_id = module.prod_webapp.app_service_plan_id
        operator           = "GreaterThan"
        statistic          = "Average"
        threshold          = "80.0"
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT10M"
      }
      scale_action {
        cooldown  = "PT5M"
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "MemoryPercentage"
        metric_resource_id = module.prod_webapp.app_service_plan_id
        operator           = "LessThan"
        statistic          = "Average"
        threshold          = "60.0"
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT10M"
      }
      scale_action {
        cooldown  = "PT5M"
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
      }
    }
  }
  tags = local.tags
}
