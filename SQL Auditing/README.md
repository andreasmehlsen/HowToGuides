
# Azure Policy for SQL Server Auditing Settings

## Overview

This Azure Policy ensures that SQL servers have auditing settings enabled and configured to send audit logs to a specified Log Analytics workspace. The policy deploys the necessary auditing settings if they do not already exist.

This policy should limits the SQLSecurityAuditEvents to the authentication events and only keeps the rention to 30 days.

## Policy Definition

### Mode
- **Indexed**: The policy is evaluated based on the indexed properties of resources.

### Policy Rule

#### If Condition
- **Field**: `type`
- **Equals**: `Microsoft.Sql/servers`
- The policy applies to resources of type `Microsoft.Sql/servers`.

#### Then Condition
- **Effect**: `[parameters('effect')]`
- The effect of the policy is determined by the `effect` parameter, which can be either `DeployIfNotExists` or `Disabled`.

##### Details
- **Type**: `Microsoft.Sql/servers/auditingSettings`
- **Name**: `Default`
- **Existence Condition**:
  - **Field**: `Microsoft.Sql/auditingSettings.state`
  - **Equals**: `Enabled`
- **Role Definition IDs**:
  - `/providers/Microsoft.Authorization/roleDefinitions/056cd41c-7e88-42e1-933e-88ba6a50c9c3`
  - `/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293`
- **Deployment**:
  - **Properties**:
    - **Mode**: `incremental`
    - **Template**:
      - **Schema**: `http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#`
      - **Content Version**: `1.0.0.0`
      - **Parameters**:
        - **serverName**: `string`
        - **logAnalyticsWorkspaceId**: `string`
      - **Variables**:
        - **diagnosticSettingsName**: `SQLSecurityAuditEvents_3d229c42-c7e7-4c97-9a99-ec0d0d8b86c1`
      - **Resources**:
        - **Diagnostic Settings**:
          - **Type**: `Microsoft.Sql/servers/databases/providers/diagnosticSettings`
          - **Name**: `[concat(parameters('serverName'),'/master/microsoft.insights/',variables('diagnosticSettingsName'))]`
          - **API Version**: `2017-05-01-preview`
          - **Properties**:
            - **Name**: `[variables('diagnosticSettingsName')]`
            - **Workspace ID**: `[parameters('logAnalyticsWorkspaceId')]`
            - **Logs**:
              - **Category**: `SQLSecurityAuditEvents`
              - **Enabled**: `true`
              - **Retention Policy**:
                - **Days**: `30`
                - **Enabled**: `false`
        - **Auditing Settings**:
          - **Name**: `[concat(parameters('serverName'), '/Default')]`
          - **Type**: `Microsoft.Sql/servers/auditingSettings`
          - **API Version**: `2017-03-01-preview`
          - **Depends On**:
            - `[concat('Microsoft.Sql/servers/', parameters('serverName'),'/databases/master/providers/microsoft.insights/diagnosticSettings/', variables('diagnosticSettingsName'))]`
          - **Properties**:
            - **State**: `Enabled`
            - **Is Azure Monitor Target Enabled**: `true`
            - **Audit Actions and Groups**: `["SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP"]`

## Parameters

### logAnalyticsWorkspaceId
- **Type**: `String`
- **Metadata**:
  - **Display Name**: `Log Analytics workspace`
  - **Description**: `Specify the Log Analytics workspace the server should be connected to.`
  - **Strong Type**: `omsWorkspace`
  - **Assign Permissions**: `true`

### effect
- **Type**: `String`
- **Metadata**:
  - **Display Name**: `Effect`
  - **Description**: `Enable or disable the execution of the policy`
- **Allowed Values**:
  - `DeployIfNotExists`
  - `Disabled`
- **Default Value**: `DeployIfNotExists`

## Conclusion

This policy ensures that SQL servers have auditing settings enabled and configured to send audit logs to a specified Log Analytics workspace. It deploys the necessary settings if they do not already exist, helping to maintain compliance and security within your Azure environment.
