
#connect to account
Connect-AzAccount -UseDeviceAuthentication

# select location
Get-AzLocation | select Location
$location = "eastus"

#create resource group
$resourceGroup = "myResourceGroup"
New-AzResourceGroup -Name $resourceGroup -Location $location


# get storage accountes
$storageAccount = Get-AzStorageAccount -ResourceGroupName "myResourceGroup" -Name "store1mystorage03062021"
$storageAccountb = Get-AzStorageAccount -ResourceGroupName "myResourceGroup" -Name "store2mystorage03062021"
$ctx = $storageAccount.Context
$ctxb = $storageAccountb.Context

#create containers
$containerName = "test3"
New-AzStorageContainer -Name $containerName -Context $ctx -Permission blob
$containerNameB = "test3"
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

#####