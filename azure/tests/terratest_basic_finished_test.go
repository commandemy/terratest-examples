package test

import (
	"testing"

	"github.com/Azure/azure-sdk-for-go/services/compute/mgmt/2019-07-01/compute"
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformAzureExample(t *testing.T) {
	t.Parallel()

	uniquePostfix := random.UniqueId()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../terraform/basics",
		Vars: map[string]interface{}{
			"postfix": uniquePostfix,
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	vmName := terraform.Output(t, terraformOptions, "vm_name")
	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")

	// Lab 4.3 Add disk outputs
	diskName := terraform.Output(t, terraformOptions, "disk_name")

	// Lab 4.4 Image version
	imageVersion := terraform.Output(t, terraformOptions, "image_version")

	// Look up the size of the given Virtual Machine and ensure it matches the output.
	actualVMSize := azure.GetSizeOfVirtualMachine(t, vmName, resourceGroupName, "")
	expectedVMSize := compute.VirtualMachineSizeTypes("Standard_B1s")
	assert.Equal(t, expectedVMSize, actualVMSize)

	// Lab 4.3 Assert the value
	actualDiskName := azure.GetVirtualMachineOSDiskName(t, vmName, resourceGroupName, "")
	assert.Equal(t, diskName, actualDiskName)

	// Lab 4.4 Check for VM Image
	actualVMImage := azure.GetVirtualMachineImage(t, vmName, resourceGroupName, "")
	assert.Equal(t, imageVersion, actualVMImage.SKU)
}
