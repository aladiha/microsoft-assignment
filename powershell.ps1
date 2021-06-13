#connect to account
Connect-AzAccount -UseDeviceAuthentication

# select location
$location = "eastus" 

#create resource group
$resourceGroup = "aladinHandoRes3"
$storageAcc1 = "aladinsourcestorage12345"
$storageAcc2 = "aladindeststorage12345"
$VmStorageAcc = "aladinbootdiagnostic"

#get azureuser admin name
[string]$path = Get-Location
$pathArray = $path.Split("/")
$azureuser = $pathArray[2]

#create azure resource group
New-AzResourceGroup -Name $resourceGroup -Location $location

#create storage accounts
New-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name $storageAcc1 `
    -Location $location `
    -SkuName Standard_RAGRS `
    -Kind StorageV2

New-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name $storageAcc2 `
    -Location $location `
    -SkuName Standard_RAGRS `
    -Kind StorageV2

#create storage account for vm config
New-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name $VmStorageAcc `
    -Location $location `
    -SkuName Standard_RAGRS `
    -Kind StorageV2

#Generating public/private rsa key pair
ssh-keygen -t rsa -b 4096

# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
    -Name "mySubnet" `
    -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name "myVNET" `
  -AddressPrefix 192.168.0.0/16 `
  -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -AllocationMethod Static `
  -IdleTimeoutInMinutes 4 `
  -Name "mypublicdns$(Get-Random)"

# Create an inbound network security group rule for port 22
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
  -Name "myNetworkSecurityGroupRuleSSH"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 22 `
  -Access "Allow"

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzNetworkSecurityRuleConfig `
  -Name "myNetworkSecurityGroupRuleWWW"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access "Allow"


# Create a network security group
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name "myNetworkSecurityGroup" `
  -SecurityRules $nsgRuleSSH,$nsgRuleWeb

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface `
  -Name "myNic" `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Define a credential object
$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($azureuser, $securePassword)

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig `
  -VMName "myVM" `
  -VMSize "Standard_DS1_v2" | `
Set-AzVMOperatingSystem `
  -Linux `
  -ComputerName "myVM" `
  -Credential $cred `
  -DisablePasswordAuthentication | `
Set-AzVMSourceImage `
  -PublisherName "Canonical" `
  -Offer "UbuntuServer" `
  -Skus "18.04-LTS" `
  -Version "latest" | `
Add-AzVMNetworkInterface `
  -Id $nic.Id

#save vm configurations in storage account
Set-AzVMBootDiagnostic -VM $vmConfig -Enable -ResourceGroupName $resourceGroup -StorageAccountName $VmStorageAcc

# Configure the SSH key
$sshPublicKey = cat ~/.ssh/id_rsa.pub
Add-AzVMSshPublicKey `
  -VM $vmconfig `
  -KeyData $sshPublicKey `
  -Path "/home/$azureuser/.ssh/authorized_keys"

#create VM
New-AzVM `
  -ResourceGroupName $resourceGroup `
  -Location eastus -VM $vmConfig

#get public ip for vm connection 
Get-AzPublicIpAddress -ResourceGroupName $resourceGroup | Select "IpAddress"




