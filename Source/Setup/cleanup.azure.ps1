Param([string] $configFile)

[xml]$xml = Get-Content $configFile

Set-AzureSubscription -SubscriptionName $xml.configuration.subscriptionName -CurrentStorageAccount $xml.configuration.storageAccount.name
Select-AzureSubscription -SubscriptionName $xml.configuration.subscriptionName

# Remove Everything Previously Created

Remove-AzureService -ServiceName $xml.configuration.cloudServiceName1 -Force

Get-AzureDisk | Where { $_.DiskName -like '*ad-dc*' -and $_.AttachedTo -eq $null } | Remove-AzureDisk -DeleteVHD
Get-AzureDisk | Where { $_.DiskName -like '*ad-ms*' -and $_.AttachedTo -eq $null } | Remove-AzureDisk -DeleteVHD

