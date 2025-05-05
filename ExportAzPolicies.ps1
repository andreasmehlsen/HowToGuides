Get-AzPolicyAssignment `
| Select-Object -Property DisplayName, Scope, PolicyDefinitionId, @{
    Name = 'ManagementGroup'
    Expression = {
        if ($_.Scope -match '/providers/Microsoft.Management/managementGroups/([^/]+)') {
            $matches[1]
        }
        else {
            $null
        }
    }
} `
| Export-Csv -Path "./policyAssignments.csv" -NoTypeInformation