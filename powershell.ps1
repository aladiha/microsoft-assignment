
Connect-AzAccount
<#
# select location
Get-AzLocation | select Location
$location = "eastus"

#create resource group
$resourceGroup = "myResourceGroup"
New-AzResourceGroup -Name $resourceGroup -Location $location
#>
$storageAccount = Get-AzStorageAccount -ResourceGroupName "myResourceGroup" -Name "store1mystorage03062021"
$storageAccountb = Get-AzStorageAccount -ResourceGroupName "myResourceGroup" -Name "store2mystorage03062021"

$ctx = $storageAccount.Context
$ctxb = $storageAccountb.Context

$containerName = "test1"
New-AzStorageContainer -Name $containerName -Context $ctx -Permission blob

$containerNameB = "test2"
New-AzStorageContainer -Name $containerNameB -Context $ctxb -Permission blob


for ($num = 1 ; $num -le 100 ; $num++){
  [string]$index = $num.ToString()
  Set-AzStorageBlobContent -File "/Users/aladinhandoklo/Desktop/files/$index.txt" `
    -Container $containerName `
    -Blob "blob$index.txt" `
    -Context $ctx 
}


Get-AzStorageBlob -Context $ctx `
-Container $containerName | Start-AzStorageBlobCopy -DestContext $ctxb `
-DestContainer $containerNameB
