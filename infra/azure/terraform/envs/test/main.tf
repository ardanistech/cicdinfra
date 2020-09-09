terraform {
  required_version = ">= 0.13.0"

  required_providers {
    azure = {
      source  = "hashicorp/azurerm"
      version = ">= 2.25.0"
    }
  }

  backend azurerm {
    resource_group_name  = "cicdinfra"
    storage_account_name = "cicdinfra"
    container_name       = "terraform-test"
    key                  = "terraform.tfstate"
  }
}

provider azurerm {
  subscription_id = var.azure_subscription_id
  features {}
}

module globals {
  source = "../../global-variables"
}
