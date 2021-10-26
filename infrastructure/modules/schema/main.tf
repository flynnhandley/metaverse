resource "null_resource" "example1" {
  provisioner "local-exec" {
      when    = create
      command = ". ${path.module}/assets/create_schema.sh"

      environment = {
        schema              = var.schema
        schema_name         = var.schema_name
        schema_group        = var.schema_group
        eventhub_namespace  = var.eventhub_namespace
        eventhub            = var.eventhub
      }
  }
}

# file("${path.module}/schema.json")