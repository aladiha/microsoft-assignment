Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

#connect to account
Connect-AzAccount -UseDeviceAuthentication

#select ResorceGroup
$resourceGroup = "aladinHandoRes3"

#select source storage account and container
$sourceStorageAcc = "aladinsourcestorage12345"
$sourceContainer = "sorurce"

#select destination storage account and container
$destStorageAcc = "aladindeststorage12345"
$destContainer = "destination"

#get azureuser admin name
[string]$path = Get-Location
$pathArray = $path.Split("/")
$azureuser = $pathArray[2]

#get storage accountes
$sourceAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $sourceStorageAcc
$destAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $destStorageAcc
$ctx = $sourceAccount.Context
$ctxb = $destAccount.Context

#create containers
New-AzStorageContainer -Name $sourceContainer -Context $ctx -Permission blob
New-AzStorageContainer -Name $destContainer -Context $ctxb -Permission blob

new-item \home\aladin_hando\files -itemtype directory


# create files in VM machine
for ($num = 1 ; $num -le 100 ; $num++){
    [string]$index = $num.ToString()
    New-Item "\home\aladin_hando\files\$index.txt"
    Set-Content "\home\$azureuser\files\$index.txt" "file number $index"
}

#upload files to azure sorage account
for ($num = 1 ; $num -le 100 ; $num++){
  [string]$index = $num.ToString()
  Set-AzStorageBlobContent -File "/home/$azureuser/files/$index.txt" `
    -Container $sourceContainer `
    -Blob "blob$index.txt" `
    -Context $ctx 
}

#copy files from one storage to another
Get-AzStorageBlob -Context $ctx `
-Container $sourceContainer | Start-AzStorageBlobCopy -DestContext $ctxb `
-DestContainer $destContainer
