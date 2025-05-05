To check the traffic logs for Azure Storage and see the connections blocked by Firewall settings in Networking, you can follow the steps below.

For testing, I have disabled Public network access in storage account, then when I try to access blob, the firewall is blocking the connection.

enter image description here

Enable diagnostic settings, skip this step if are already set up.

Go to Insights > Failures.

enter image description here

Here you can filter the log, if any traffic blocked from networking for storage transactions.
enter image description here

KQL query to check the view traffic logs for azure storage for connections that got blocked by firewall.
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
Output:


### 2. Azure Storage account monitor traffic
Run the following command to execute queries via the CLI:


```kql
StorageBlobLogs
| where OperationName == "GetBlob"
| project TimeGenerated, CallerIpAddress, OperationName
| order by TimeGenerated desc
```

Show ipadresses count:

```kql
StorageBlobLogs
| where OperationName == "GetBlob"
| summarize ConnectionAttempts = count() by tostring(CallerIpAddress)
| order by ConnectionAttempts desc
```


enter image description here