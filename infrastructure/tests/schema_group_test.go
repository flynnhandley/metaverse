package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func Test_CreateSchemaGroup(t *testing.T) {

	// Arrange
	terraformDir := "../modules/schema-group"

	subscriptionId := getSubscriptionId()
	resourceGroup := "rg-metaverse-resources"
	namespace := "ehns-metaverse"
	name := "schema"

	terraformCreateOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"name":               name,
			"subscription_id":    subscriptionId,
			"eventhub_namespace": namespace,
			"resource_group":     resourceGroup,
		},
	})

	defer terraform.Destroy(t, terraformCreateOptions)

	// Act
	terraform.InitAndApply(t, terraformCreateOptions)

	resp, _ := getSchemaGroup(namespace, name)

	// Assert
	assert.Equal(t, 200, resp.StatusCode)
}
