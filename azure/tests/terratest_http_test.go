package test

import (
	"crypto/tls"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
)

func TestTerraformAzureHttpExample(t *testing.T) {
	t.Parallel()

	uniquePostfix := random.UniqueId()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../terraform/http",
		Vars: map[string]interface{}{
			"postfix": uniquePostfix,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	instanceUrl := terraform.Output(t, terraformOptions, "instance_url")
	instanceText := "Hello, World!"

	// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
	tlsConfig := tls.Config{}

	// It can take a minute or so for the Instance to boot up, so retry a few times
	maxRetries := 30
	timeBetweenRetries := 5 * time.Second

	// Verify that we get back a 200 OK with the expected instanceText
	http_helper.HttpGetWithRetry(t, instanceUrl, &tlsConfig, 200, instanceText, maxRetries, timeBetweenRetries)
}
