#! /bin/sh
token=$(az account get-access-token --query accessToken -o tsv)
curl "https://management.azure.com$id?api-version=2018-01-01-preview" \
  -X 'PUT' \
  -H "Authorization: Bearer $token" \
  -H 'Content-Type: application/json' \
  --data-raw "$data_raw" \
  --compressed

