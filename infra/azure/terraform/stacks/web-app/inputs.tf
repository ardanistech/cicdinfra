variable azure_region {
  type = string
}

variable resource_group_name {
  type = string
}

variable storage_account_name {
  type = string
}

variable app_service_plan {
  type = object({
    name = string
    tier = string
    size = string
  })
}

variable app_service_vnet {
  type = object({
    name        = string
    subnet_name = string
    nsg_name    = string
  })
}

variable app_service {
  type = object({
    name             = string
    hostname         = string
    environment_type = string
    always_on        = bool
  })
}

variable app_service_slot {
  type = object({
    enabled          = bool
    name             = string
    environment_type = string
    always_on        = bool
  })
  default = {
    enabled          = false
    name             = "name"
    environment_type = "environment_type"
    always_on        = false
  }
}

variable app_service_tags {
  type = object({
    workload = string
    team     = string
    env      = string
  })
}

variable app_service_access_restrictions {
  type = list(object({
    ip_address     = string
    subnet_mask    = string
    vnet_subnet_id = string
  }))
}

variable postgres {
  type = object({
    name                 = string
    admin_login          = string
    admin_password       = string
    sku_name             = string
    virtual_network_rule = bool
  })
}
