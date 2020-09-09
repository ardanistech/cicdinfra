terraform {
  required_version = ">= 0.13.0"

  required_providers {
    azure = {
      source  = "hashicorp/azurerm"
      version = ">= 2.25.0"
    }
  }

  backend local {
    path = "terraform.tfstate"
  }
}

locals {
  tags = {
    workload = "infra",
    team     = "cicdinfra",
    env      = "infra"
  }

  app_service_plan_name = "cicdinfra-prod-asp"
}

module globals {
  source = "../global-variables"
}

provider azurerm {
  subscription_id = module.globals.azure_subscription_id
  features {}
}

resource azurerm_resource_group terraform_state {
  name     = module.globals.backend_storage_account_name
  location = module.globals.azure_region
  tags     = local.tags
}

resource azurerm_storage_account terraform_state {
  name                      = module.globals.backend_storage_account_name
  location                  = module.globals.azure_region
  resource_group_name       = module.globals.backend_storage_account_name
  account_tier              = "Standard"
  account_kind              = "Storage"
  account_replication_type  = "LRS"
  enable_https_traffic_only = false
  tags                      = local.tags
}

resource azurerm_storage_container test_container {
  name                  = module.globals.backend_test_container
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}

resource azurerm_storage_container prod_container {
  name                  = module.globals.backend_prod_container
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}
