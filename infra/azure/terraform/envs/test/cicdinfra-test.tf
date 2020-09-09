locals {
  tags = {
    workload = "test",
    team     = "cicdinfra",
    env      = "test"
  }
}

resource azurerm_resource_group test {
  name     = "cicdinfra-test"
  location = module.globals.azure_region
  tags     = local.tags
}

module test_webapp {
  source = "../../stacks/web-app"

  azure_region = module.globals.azure_region

  resource_group_name = azurerm_resource_group.test.name

  app_service_tags = local.tags

  app_service_plan = {
    name = "cicdinfra-test-asp"
    tier = "Basic"
    size = "B1"
  }

  app_service_vnet = {
    name        = "cicdinfra-test-vnet"
    subnet_name = "cicdinfra-test-sn"
    nsg_name    = "cicdinfra-test-nsg"
  }

  app_service = {
    name             = "cicdinfra-test-as"
    hostname         = "app.test.cicdinfra"
    environment_type = "test"
    always_on        = false
  }

  app_service_access_restrictions = []

  postgres = {
    name                 = "cicdinfra-test-pgs"
    admin_login          = var.postgres_admin_login
    admin_password       = var.postgres_admin_password
    sku_name             = "B_Gen5_1"
    virtual_network_rule = false
  }

  storage_account_name = "cicdinfratestsa"
}
