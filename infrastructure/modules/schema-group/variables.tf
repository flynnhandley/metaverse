variable "name" {}

variable "subscription_id" {}

variable "eventhub_namespace" {}

variable "resource_group" {}

variable "schema_type" {
  default = "Avro"
}

variable "schema_compatibility" {
  default = "Backward"
}