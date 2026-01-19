Param(
    [string]$SubscriptionID,
    [string]$operation
)

#$ResourceID = "/subscriptions/12345678-1234-1234-1234-123a12b12d1c/resourceGroups/fabric-rg/providers/Microsoft.Fabric/capacities/myf2capacity"
#$operation = "suspend" 
#$operation = "resume"

Connect-AzAccount -Identity

$tokenObject = Get-AzAccessToken -ResourceUrl "https://management.azure.com/"
$token = $tokenObject.Token

$azContext = Get-AzContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$tokenObject = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$token = $tokenObject.AccessToken

$url = "https://management.azure.com/subscriptions/$SubscriptionID/providers/Microsoft.Fabric/capacities?api-version=2023-11-01"
#Write-Output $url

$headers = @{
    'Content-Type' = 'application/json'
    'Authorization' = "Bearer $token"
}

$response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers

foreach($o in $response){
    $ResourceID = $o
    $o | ForEach-Object -Process { 
        $_
        Write-Output $_.value.Count
        Write-Output $_.value.GetType()
        $_.value.id | ForEach-Object -Process {
            $url = "https://management.azure.com/$_/$operation" + "?api-version=2023-11-01"
            $headers = @{
                'Content-Type' = 'application/json'
                'Authorization' = "Bearer $token"
            }
            #Write-Output $url
            $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers
        
            $response
            }
        }
}

