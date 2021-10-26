terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.82.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
    prefix      = "metaverse"
    location    = "australiasoutheast"
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.prefix}-resources"
  location = "${local.location}"
}

module "schema_group" {
  source = "./modules/schema-group"

  name                = "example-schema-group"
  subscription_id     = data.azurerm_client_config.current.subscription_id
  eventhub_namespace  = azurerm_eventhub_namespace.main.name
  resource_group      = azurerm_resource_group.main.name
}

module "schema" {
  source = "./modules/schema"

  schema              = file("${path.module}/schema/example.json")
  schema_name         = "example-schema"
  eventhub_namespace  = azurerm_eventhub_namespace.main.name
  eventhub            = azurerm_eventhub.main.name
  schema_group        = module.schema_group.name
  
  depends_on = [
    module.schema_group
  ]
}

resource "azurerm_user_assigned_identity" "consuming_api" {
  name                = "id-consuming-api"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_user_assigned_identity" "producing_api" {
  name                = "id-producing-api"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_storage_account" "main" {
  name                = "sa${local.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_eventhub_namespace" "main" {
  name                = "ehns-${local.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  capacity            = 2

  tags = {
    environment = "mains"
  }
}

resource "azurerm_eventhub_namespace_authorization_rule" "consumer" {
  name                = "${local.prefix}-consumer"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = azurerm_resource_group.main.name

  listen = true
  send   = false
  manage = false
}

resource "azurerm_eventhub_namespace_authorization_rule" "producer" {
  name                = "${local.prefix}-consumer"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = azurerm_resource_group.main.name

  listen = false
  send   = true
  manage = false
}

resource "azurerm_eventhub" "main" {
  name                = "eh-${local.prefix}"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = azurerm_resource_group.main.name

  partition_count   = 2
  message_retention = 1

  capture_description {
    enabled  = true
    encoding = "Avro"

    destination {
      name = "EventHubArchive.AzureBlockBlob"

      # Example: main-ehnamespace/test/0/2021/10/25/22/54/58
      archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
      blob_container_name = "${azurerm_storage_data_lake_gen2_filesystem.main.name}"
      storage_account_id  = "${azurerm_storage_account.main.id}"
    }
  }
}

resource "azurerm_eventhub_consumer_group" "consumer1" {
  name                = "${local.prefix}-consumer1"
  namespace_name      = azurerm_eventhub_namespace.main.name
  eventhub_name       = azurerm_eventhub.main.name
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_role_assignment" "storageAccountRoleAssignment" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "main" {
  name               = "main"
  storage_account_id = azurerm_storage_account.main.id
  ace {
    type        = "user"
    permissions = "rwx"
  }
  ace {
    type        = "user"
    id          = azurerm_user_assigned_identity.consuming_api.principal_id
    permissions = "--x"
  }
  ace {
    type        = "group"
    permissions = "r-x"
  }
  ace {
    type        = "mask"
    permissions = "r-x"
  }
  ace {
    type        = "other"
    permissions = "---"
  }
  depends_on = [
    azurerm_role_assignment.storageAccountRoleAssignment
  ]
}

resource "azurerm_storage_data_lake_gen2_path" "raw" {
  storage_account_id = azurerm_storage_account.main.id
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.main.name
  path               = "raw"
  resource           = "directory"
  ace {
    type        = "user"
    permissions = "r-x"
  }
  ace {
    type        = "user"
    id          = azurerm_user_assigned_identity.consuming_api.principal_id
    permissions = "r-x"
  }
  ace {
    type        = "group"
    permissions = "-wx"
  }
  ace {
    type        = "mask"
    permissions = "--x"
  }
  ace {
    type        = "other"
    permissions = "--x"
  }
  ace {
    scope       = "default"
    type        = "user"
    permissions = "r-x"
  }
  ace {
    scope       = "default"
    type        = "user"
    id          = azurerm_user_assigned_identity.consuming_api.principal_id
    permissions = "r-x"
  }
  ace {
    scope       = "default"
    type        = "group"
    permissions = "-wx"
  }
  ace {
    scope       = "default"
    type        = "mask"
    permissions = "--x"
  }
  ace {
    scope       = "default"
    type        = "other"
    permissions = "--x"
  }
}
