package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

var schema = `
{
    "type": "record",
    "name": "flynnHandley",
    "namespace": "com.azure.schemaregistry.samples",
    "fields": [
        {
            "name": "name",
            "type": "string"
        },
        {
            "name": "favoriteNumber",
            "type": "int"
        }
    ]
}`

func Test_CreateSchemaVersion(t *testing.T) {

	subscriptionId := getSubscriptionId()
	resourceGroup := "rg-metaverse-resources"
	namespace := "ehns-metaverse"
	schemaGroupName := "testschemagroup"
	schemaName := "testschema"
	eventhubName := "test-event-hub"

	// Arrange
	schemaGroupModuleDir := "../modules/schema-group"
	schemaModuleDir := "../modules/schema"

	schemaGroupCreateOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: schemaGroupModuleDir,
		Vars: map[string]interface{}{
			"name":               schemaGroupName,
			"subscription_id":    subscriptionId,
			"eventhub_namespace": namespace,
			"resource_group":     resourceGroup,
		},
	})

	schemaCreateOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: schemaModuleDir,
		Vars: map[string]interface{}{
			"schema":             schema,
			"schema_name":        schemaName,
			"schema_group":       schemaGroupName,
			"eventhub":           eventhubName,
			"eventhub_namespace": namespace,
		},
	})

	defer terraform.Destroy(t, schemaGroupCreateOptions)
	defer terraform.Destroy(t, schemaCreateOptions)

	terraform.InitAndApply(t, schemaGroupCreateOptions)

	_, err := os.ReadFile("./assets/schema.json")

	check(err)

	// Act
	terraform.InitAndApply(t, schemaCreateOptions)

	resp, _ := getSchema(namespace, schemaName)

	// Assert
	assert.Equal(t, 200, resp.StatusCode)
}
