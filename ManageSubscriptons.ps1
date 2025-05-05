CLS
# Uninstall-Module -Name Az.Accounts
# Install-Module Az.Monitor
# install-Module -Name Az.Accounts
install-Module -Name Az.Resources
Import-Module Az.Monitor
Import-Module Az.resources
Import-Module Az.Accounts
 
# Define default tags (these will be updated dynamically per subscription)
$defaultTags = @{
    "Environment"     = "Development"
    "Geo-restrictions" = "n/a"
    "Repository"      = "N/A"
    "Deployment type" = "Manual"
    "Solution type"   = "Production IT"
    "Department"      = ""
}
 
# Login to Azure (make sure you are logged in)
Connect-AzAccount 
 
# Get enabled subscriptions
$subscriptions = Get-AzSubscription | Where-Object { 
    ($_.State -eq 'Enabled') # -and ($_.id -eq "7b608b00-1fbe-4bed-acf0-1f24c739a4e4")  
}
 
foreach ($subscription in $subscriptions) {
    Write-Host "Checking subscription: $($subscription.Name) ($($subscription.Id))"
 
    # Set context to the current subscription
    Set-AzContext -SubscriptionId $subscription.Id | Out-Null
 
    # Get current tags
    $subInfo = Get-AzSubscription -SubscriptionId $subscription.Id
    $currentTags = $subInfo.Tags
 
    if (-not $currentTags) { $currentTags = @{} }
 
    # Get quota ID via REST
    $token = (Get-AzAccessToken -AsSecureString -ResourceUrl "https://management.azure.com/").Token
    $token = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))
    $uri = "https://management.azure.com/subscriptions/$($subscription.Id)?api-version=2020-01-01"
    $response = Invoke-RestMethod -Uri $uri -Headers @{ Authorization = "Bearer $token" }
 
    $quotaId = $response.subscriptionPolicies.quotaId
 
    # Determine environment and solution type from quota ID
    switch -Wildcard ($quotaId) {
        "EnterpriseAgreement*" {
            $defaultTags["Application Name"] = $response.displayName
            $defaultTags["Environment"] = "Production"
            $defaultTags["Solution type"] = "Production IT"
        }
        "MSDND*" { 
            $defaultTags["Application Name"] = $response.displayName
            $defaultTags["Environment"] = "Development" 
        }
        "MSDN*" { 
            $defaultTags["Application Name"] = "Sandbox for <initials>" 
            $defaultTags["Environment"] = "Development"
            $defaultTags["Solution type"] = "Production IT"
            $defaultTags["Department"] = "DevOps & Container Services - DK31000025"
        }
        "FreeTrial*" { 
            $defaultTags["Application Name"] = $response.displayName
            $defaultTags["Environment"] = "Trial"
            $defaultTags["Solution type"] = "Production IT"
        }
        "Sponsor*" { 
            $defaultTags["Application Name"] = $response.displayName
            $defaultTags["Environment"] = "Demonstration"
            $defaultTags["Solution type"] = "Production IT"
        }
        "PayAsYouGo*" { 
            $defaultTags["Application Name"] = $response.displayName
            $defaultTags["Environment"] = "Pay-as-you-go" 
        }
        default {
            $defaultTags["Environment"] = "Unknown"
        }
    }
 
    # Attempt to find the subscription creator from activity logs
    try {
        $activityLog = Get-AzLog -StartTime (Get-Date).AddDays(-90) `
            | Where-Object { $_.OperationName.Value -like "*Create*" -or $_.Authorization.Action -like "*write*" } `
            | Sort-Object EventTimestamp | Select-Object -First 1
 
        if ($activityLog.Caller) {
            $defaultTags["Comment"] = $activityLog.Caller
        } else {
            $defaultTags["Comment"] = "Unknown (No log caller)"
        }
    } catch {
        $defaultTags["Comment"] = "Unknown (log error)"
        Write-Warning "Could not retrieve creator for subscription $($subscription.Id): $_"
    }
 
    # Merge tags: Add missing tags from $defaultTags
    foreach ($key in $defaultTags.Keys) {
        if (-not $currentTags.ContainsKey($key)) {
            $currentTags[$key] = $defaultTags[$key]
        }
    }
 
    if ($currentTags.ContainsKey("Geo-restriction")) {
        Write-Host "Removing tag 'Geo-restriction' from subscription $($subscription.Name)"
        $currentTags.Remove("Geo-restriction")
    }
    if ($currentTags.ContainsKey("Deployer")) {
        Write-Host "Removing tag 'Deployer' from subscription $($subscription.Name)"
        $currentTags.Remove("Deployer")
    }
 
    # Apply updated tags
    Write-Host "Updating tags for subscription: $($subscription.Name)"
    $currentTags
#    Set-AzSubscription -SubscriptionId $subscription.Id -Tag $currentTags
    New-AzTag -ResourceId "/subscriptions/$($subscription.Id)"  -Tag $currentTags
}