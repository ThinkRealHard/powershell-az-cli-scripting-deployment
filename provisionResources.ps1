# TODO: set variables
$studentName = "allentouchstoneoutlook"
$rgName = "$studentName-lc-rg"
$vmName = "$studentName-lc-vm"
$vmSize = "Standard_B2s"
$vmImage = "$(az vm image list --query "[? contains(urn, 'Ubuntu')] | [0].urn")"
$vmAdminUsername = "student"
$kvName = "$studentName-lc0820-ps-kv"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

az configure --default location=eastus

# TODO: provision RG

az group create -n $rgName

az configure --default group=$rgName | Set-Content rg.json

# TODO: provision VM

az vm create -n $vmName --size $vmSize --image $vmImage --admin-username $vmAdminUsername --admin-password "LaunchCode-@zure1" --authentication-type "password" --assign-identity | Set-Content vm.json

az configure --default vm=$vmName

# TODO: capture the VM systemAssignedIdentity

$vm = Get-Content vm.json | ConvertFrom-Json

# TODO: open vm port 443

az vm open-port --port 443

# provision KV

az keyvault create -n $kvName --enable-soft-delete false --enabled-for-deployment true | Set-Content kv.json

# TODO: create KV secret (database connection string)

az keyvault secret set --vault-name $kvName --description "db connection string" --name $kvSecretName --value $kvSecretValue

# TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)

az keyvault set-policy --name "$kvName" --object-id $vm.identity.systemAssignedIdentity --secret-permissions list get

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/1configure-vm.sh

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/2configure-ssl.sh

az vm run-command invoke --command-id RunShellScript --scripts @deliver-deploy.sh


# TODO: print VM public IP address to STDOUT or save it as a file

Write-Output $vm.publicIpAddress
