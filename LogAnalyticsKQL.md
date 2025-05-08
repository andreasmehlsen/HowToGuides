# Azure Log analytics workspace KQLs

To check the traffic logs for Azure Storage and see the connections blocked by Firewall settings in Networking, follow these steps.

## Testing Scenario
For testing, disable Public network access in the storage account. Then, attempt to access a blob. If the firewall is blocking the connection, you will observe failed access attempts.

![enter image description here](#)

## Enable Diagnostic Settings
Skip this step if diagnostic settings are already set up.

## Check Failures in Insights
1. Navigate to **Insights** > **Failures**.
2. Filter the log to identify traffic blocked by networking for storage transactions.

![enter image description here](#)

## KQL Query to View Key vault Connections
Use the following Kusto Query Language (KQL) query to check the traffic logs for Azure Key vault and identify connections

```kql
AzureDiagnostics
| where ResourceType == "VAULTS" and Category == "AuditEvent"
| where OperationName has_any ("SecretGet", "SecretSet", "KeyGet", "KeyCreate", "KeyDelete", "CertificateGet")
| project
    TimeGenerated,
    OperationName,
    ResultType,
    VaultName = Resource,
    ResourceId
| order by TimeGenerated desc
```

## KQL Query to View all Connections in storage account
Use the following Kusto Query Language (KQL) query to check the traffic logs for Azure Storage blob

[Azure Storage Account KQLs](https://learn.microsoft.com/en-us/azure/storage/blobs/monitor-blob-storage?tabs=azure-portal)

```kql
StorageBlobLogs
| where OperationName in ("GetBlob", "PutBlob", "DeleteBlob")  // focus on read/write ops
| project
    TimeGenerated,
    RequesterAppId,
    CallerIpAddress,
    Uri,
    AuthenticationType,
    Protocol,
    RequestBodySize,
    ResponseBodySize
| order by TimeGenerated desc
```

## KQL Query to View all Connections in Web apps
Use the following Kusto Query Language (KQL) query to check the traffic logs for Azure Web apps

```kql
AppServiceHTTPLogs 
| where ScStatus == 200
```

Top 15 machines which are generating traffic.

```kql
AppServiceHTTPLogs
| top-nested of _ResourceId by dummy=max(0), // Display results for each resource (App)
  top-nested 15 of CIp by count()
| project-away dummy // Remove dummy line from the result set
```

## KQL Query to View all Connections in App Configuration
Use the following Kusto Query Language (KQL) query to check the traffic logs for Azure App Configuration

[Azure App Configuration KQLs](https://learn.microsoft.com/en-us/azure/azure-app-configuration/monitor-app-configuration?tabs=portal)

List the number of requests sent in the last three days by IP Address

```kql
AACHttpRequest
    | where TimeGenerated > ago(3d)
    | summarize requestCount=sum(HitCount) by ClientIPAddress
    | order by requestCount desc
```

## Output
