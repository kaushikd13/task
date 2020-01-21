Connect-AzAccount
# $DeploymentName = "DCT-DevTestLab"
#$DeploymentLocation = "EastUS"
$ResourceGroupName = "DCT"
$ResourceGroupLocation = "EastUS"
# New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation
New-AzResourceGroupDeployment `
   -ResourceGroupName $ResourceGroupName `
   -TemplateFile azuredeploy.json `
   -TemplateParameterFile azuredeploy.parameters.json

#New-AzDeployment `
#   -Name $DeploymentName `
#   -Location $DeploymentLocation `
#   -TemplateFile azuredeploy.json `
#   -TemplateParameterFile azuredeploy.parameters.json