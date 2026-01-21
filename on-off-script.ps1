Param(
    [string]$SubscriptionID,
    [string]$operation
)

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

Invoke-RestMethod -Uri $url -Method Get -Headers $headers | ForEach-Object -Process{
    $c = 0
    $_.value| ForEach-Object -Process{
        #Write-Output $_
        Write-Output "count: $($c)"
        Write-Output $_.properties.state
        if ((("suspend" -eq $operation) -and ("Active" -eq $_.properties.state)) -or (("resume" -eq $operation) -and ("Paused" -eq $_.properties.state))) {
          $url = "https://management.azure.com/$($_.id)/$operation" + "?api-version=2023-11-01"
          $headers = @{
              'Content-Type' = 'application/json'
              'Authorization' = "Bearer $token"
          }
          Write-Output $url
          $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers                 
          #$response
        }else{
            Write-Output "not active : $($_.properties.state)"
        }
        $c = $c + 1
  }
}
