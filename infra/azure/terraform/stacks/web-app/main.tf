terraform {
  required_version = ">= 0.12"
}

locals {
  os                = "Linux"
  framework_version = "DOTNETCORE|3.1"
}

module globals {
  source = "../../global-variables"
}

resource azurerm_virtual_network web_app {
  name                = var.app_service_vnet.name
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  address_space       = ["10.2.0.0/16", ]
  tags                = var.app_service_tags
}

resource azurerm_network_security_group web_app {
  name                = var.app_service_vnet.nsg_name
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  tags                = var.app_service_tags
}

resource azurerm_subnet web_app {
  name                 = var.app_service_vnet.subnet_name
  virtual_network_name = azurerm_virtual_network.web_app.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = ["10.2.2.0/24"]
  service_endpoints    = ["Microsoft.Web", "Microsoft.Sql"]
  delegation {
    name = "47104e7ec2214f99803b94b35b31c89a"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      name    = "Microsoft.Web/serverFarms"
    }
  }
}

resource azurerm_subnet_network_security_group_association web_app {
  subnet_id                 = azurerm_subnet.web_app.id
  network_security_group_id = azurerm_network_security_group.web_app.id
}

resource azurerm_app_service_plan web_app {
  name                = var.app_service_plan.name
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  kind                = local.os
  reserved            = true
  sku {
    capacity = 1
    tier     = var.app_service_plan.tier
    size     = var.app_service_plan.size
  }
  tags = var.app_service_tags
}

resource azurerm_app_service web_app {
  name                = var.app_service.name
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  app_service_plan_id = azurerm_app_service_plan.web_app.id
  https_only          = false
  site_config {
    linux_fx_version = local.framework_version
    default_documents = [
      "Default.htm",
      "Default.html",
      "Default.asp",
      "index.htm",
      "index.html",
      "iisstart.htm",
      "default.aspx",
      "index.php",
    "hostingstart.html"]
    http2_enabled             = true
    use_32_bit_worker_process = true
    always_on                 = var.app_service.always_on
    scm_type                  = "VSTSRM"
    dynamic "ip_restriction" {
      for_each = var.app_service_access_restrictions

      content {
        ip_address                = ip_restriction.value.ip_address
        virtual_network_subnet_id = ip_restriction.value.vnet_subnet_id
      }
    }
  }
  app_settings = {
    "APPINSIGHTS_PORTALINFO" : "ASP.NETCORE",
    "APPINSIGHTS_PROFILERFEATURE_VERSION" : "1.0.0",
    "APPINSIGHTS_SNAPSHOTFEATURE_VERSION" : "1.0.0",
    "ASPNETCORE_ENVIRONMENT" : var.app_service.environment_type,
    "ApplicationInsightsAgent_EXTENSION_VERSION" : "~2",
    "DiagnosticServices_EXTENSION_VERSION" : "~3",
    "InstrumentationEngine_EXTENSION_VERSION" : "disabled",
    "MobileAppsManagement_EXTENSION_VERSION" : "latest"
    "MSDEPLOY_RENAME_LOCKED_FILES" : "1",
    "SnapshotDebugger_EXTENSION_VERSION" : "disabled",
    "WEBSITE_NODE_DEFAULT_VERSION" : "12.9.1",
    "XDT_MicrosoftApplicationInsights_BaseExtensions" : "disabled",
    "XDT_MicrosoftApplicationInsights_Mode" : "recommended"
  }
  tags = var.app_service_tags
}

resource azurerm_app_service_virtual_network_swift_connection web_app {
  app_service_id = azurerm_app_service.web_app.id
  subnet_id      = azurerm_subnet.web_app.id
}

resource azurerm_app_service_slot web_app_slot {
  count = var.app_service_slot.enabled ? 1 : 0

  name                = var.app_service_slot.name
  location            = var.azure_region
  resource_group_name = var.resource_group_name
  app_service_name    = azurerm_app_service.web_app.name
  app_service_plan_id = azurerm_app_service_plan.web_app.id
  https_only          = false
  site_config {
    linux_fx_version = local.framework_version
    default_documents = [
      "Default.htm",
      "Default.html",
      "Default.asp",
      "index.htm",
      "index.html",
      "iisstart.htm",
      "default.aspx",
      "index.php",
    "hostingstart.html"]
    http2_enabled             = true
    use_32_bit_worker_process = true
    always_on                 = var.app_service_slot.always_on
    scm_type                  = "VSTSRM"
    dynamic "ip_restriction" {
      for_each = var.app_service_access_restrictions

      content {
        ip_address                = ip_restriction.value.ip_address
        virtual_network_subnet_id = ip_restriction.value.vnet_subnet_id
      }
    }
  }
  app_settings = {
    "APPINSIGHTS_PORTALINFO" : "ASP.NETCORE",
    "APPINSIGHTS_PROFILERFEATURE_VERSION" : "1.0.0",
    "APPINSIGHTS_SNAPSHOTFEATURE_VERSION" : "1.0.0",
    "ASPNETCORE_ENVIRONMENT" : var.app_service_slot.environment_type,
    "ApplicationInsightsAgent_EXTENSION_VERSION" : "~2",
    "DiagnosticServices_EXTENSION_VERSION" : "~3",
    "InstrumentationEngine_EXTENSION_VERSION" : "disabled",
    "MobileAppsManagement_EXTENSION_VERSION" : "latest"
    "MSDEPLOY_RENAME_LOCKED_FILES" : "1",
    "SnapshotDebugger_EXTENSION_VERSION" : "disabled",
    "WEBSITE_NODE_DEFAULT_VERSION" : "12.9.1",
    "XDT_MicrosoftApplicationInsights_BaseExtensions" : "disabled",
    "XDT_MicrosoftApplicationInsights_Mode" : "recommended"
  }
  tags = var.app_service_tags
}

resource azurerm_app_service_slot_virtual_network_swift_connection web_app_slot {
  count = var.app_service_slot.enabled ? 1 : 0

  app_service_id = azurerm_app_service.web_app.id
  slot_name      = azurerm_app_service_slot.web_app_slot[0].name
  subnet_id      = azurerm_subnet.web_app.id
}

resource azurerm_postgresql_server web_app {
  name                = var.postgres.name
  location            = var.azure_region
  resource_group_name = var.resource_group_name

  administrator_login          = var.postgres.admin_login
  administrator_login_password = var.postgres.admin_password

  version                      = "11"
  ssl_enforcement_enabled      = true
  tags                         = var.app_service_tags
  sku_name                     = var.postgres.sku_name
  auto_grow_enabled            = true
  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
}

resource azurerm_postgresql_virtual_network_rule web_app {
  count = var.postgres.virtual_network_rule ? 1 : 0

  name                                 = "${azurerm_virtual_network.web_app.name}-postgresql-rule"
  resource_group_name                  = var.resource_group_name
  server_name                          = azurerm_postgresql_server.web_app.name
  subnet_id                            = azurerm_subnet.web_app.id
  ignore_missing_vnet_service_endpoint = true
}


resource azurerm_storage_account web_app {
  name                      = var.storage_account_name
  location                  = module.globals.azure_region
  resource_group_name       = var.resource_group_name
  account_tier              = "Standard"
  account_kind              = "Storage"
  account_replication_type  = "LRS"
  enable_https_traffic_only = false
  tags                      = var.app_service_tags
}
