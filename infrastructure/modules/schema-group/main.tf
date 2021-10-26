locals {
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group}/providers/Microsoft.EventHub/namespaces/${var.eventhub_namespace}/schemagroups/${var.name}"
}
resource "null_resource" "schema_group" {
  provisioner "local-exec" {
      when    = create
      command = ". ${path.module}/assets/create_schema.sh"

      environment = {
        data_raw              = "{\"id\":\"${local.id}\",\"name\":\"${var.name}\",\"properties\":{\"groupProperties\":{},\"schemaCompatibility\":\"${var.schema_compatibility}\",\"schemaType\":\"${var.schema_type}\"}}"
        id                    = local.id
      }
  }
}

