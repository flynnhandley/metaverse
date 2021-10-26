#! /bin/sh
echo $schema
token=$(az account get-access-token --resource https://$eventhub_namespace.servicebus.windows.net --query accessToken -o tsv)
curl "https://$eventhub_namespace.servicebus.windows.net/\$schemagroups/$schema_group/schemas/$schema_name?api-version=2020-09-01-preview" \
  -X 'PUT' \
  -H "Authorization: Bearer $token" \
  -H 'Content-Type: application/json' \
  -H 'Accept: */*' \
  -H 'Serialization-Type: avro' \
  --data-raw "$schema" \
  --compressed
