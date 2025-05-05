# Azure Storage Traffic Logs and Firewall Blocked Connections

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

## KQL Query to View Blocked Connections
Use the following Kusto Query Language (KQL) query to check the traffic logs for Azure Storage and identify connections blocked by the firewall.

```kql
let serviceValues = dynamic(['blob']);
let operationValues = dynamic(['*']);
let statusValues = dynamic(['AuthorizationFailure']);
StorageBlobLogs
| union StorageQueueLogs
| union StorageTableLogs
| union StorageFileLogs
| where StatusText != "Success"
| where "*" in ('blob') or ServiceType in ('blob')
| where "*" in ('*') or OperationName in ('*')
| where "*" in ('AuthorizationFailure') or StatusText in ('AuthorizationFailure')
| extend Service = ServiceType
| extend AuthType = AuthenticationType
| extend CallerIpAddress = split(CallerIpAddress, ":")[0]
| summarize ErrorCount = count()
    by
    Service,
    OperationName,
    StatusText,
    StatusCode,
    AuthType,
    tostring(CallerIpAddress),
    Uri
| sort by ErrorCount desc
```

## KQL Query to View all Connections in storage account
Use the following Kusto Query Language (KQL) query to check the traffic logs for Azure Storage blob

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





## Output

![enter image description here](#)