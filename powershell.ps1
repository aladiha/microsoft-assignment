
#connect to account
Connect-AzAccount -UseDeviceAuthentication

# select location
$location = "eastus" 

#create resource group
$resourceGroup = "aladinResGroup2"

New-AzResourceGroup -Name $resourceGroup -Location $location

#create storage accounts
New-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name "aladinsourcestorage12" `
    -Location $location `
    -SkuName Standard_RAGRS `
    -Kind StorageV2

New-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name "aladindeststorage12" `
    -Location $location `
    -SkuName Standard_RAGRS `
    -Kind StorageV2

#create storage account for vm config
New-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name "aladinsourcestorage123" `
    -Location $location `
    -SkuName Standard_RAGRS `
    -Kind StorageV2


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


# Create a network security group
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name "myNetworkSecurityGroup" `

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface `
  -Name "myNic" `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Define a credential object
$securePassword = ConvertTo-SecureString 'aaa9876123*' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azureuser", $securePassword)

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig `
  -VMName "myVM" `
  -VMSize "Standard_B1ls" | `
Set-AzVMOperatingSystem `
  -Linux `
  -ComputerName "myVM" `
  -Credential $cred `
  -DisablePasswordAuthentication | `
Set-AzVMSourceImage `
  -PublisherName "Aladin" `
  -Offer "UbuntuServer" `
  -Skus "18.04-LTS" `
  -Version "latest" | `
Add-AzVMNetworkInterface `
  -Id $nic.Id

#save vm configurations in storage account
Set-AzVMBootDiagnostic -VM $vmConfig -Enable -ResourceGroupName $resourceGroup -StorageAccountName "aladinsourcestorage123"

# Configure the SSH key
$sshPublicKey = cat ~/.ssh/id_rsa.pub
Add-AzVMSshPublicKey `
  -VM $vmconfig `
  -KeyData $sshPublicKey `
  -Path "/Users/aladinhandoklo/.ssh/authorized_keys"


Get-AzPublicIpAddress -ResourceGroupName $resourceGroup | Select "IpAddress"

#create VM
New-AzVM `
  -ResourceGroupName $resourceGroup `
  -Location eastus -VM $vmConfig


#get storage accountes
$storageAccount = Get-AzStorageAccount -ResourceGroupName "myResourceGroup" -Name "aladinsourcestorage12"
$storageAccountb = Get-AzStorageAccount -ResourceGroupName "myResourceGroup" -Name "aladindeststorage12"
$ctx = $storageAccount.Context
$ctxb = $storageAccountb.Context

#create containers
$containerName = "mybolbs"
New-AzStorageContainer -Name $containerName -Context $ctx -Permission blob
$containerNameB = "mybolbs"
New-AzStorageContainer -Name $containerNameB -Context $ctxb -Permission blob

# create files in VM machine
for ($num = 1 ; $num -le 100 ; $num++){
    [string]$index = $num.ToString()
    New-Item "\home\azureuser\files\$index.txt"
    Set-Content "\home\azureuser\files\$index.txt" "file number $index"
}

#upload files to azure sorage account
for ($num = 1 ; $num -le 100 ; $num++){
  [string]$index = $num.ToString()
  Set-AzStorageBlobContent -File "/home/azureuser/files/$index.txt" `
    -Container $containerName `
    -Blob "blob$index.txt" `
    -Context $ctx 
}

#copy files from one storage to another
Get-AzStorageBlob -Context $ctx `
-Container $containerName | Start-AzStorageBlobCopy -DestContext $ctxb `
-DestContainer $containerNameB

