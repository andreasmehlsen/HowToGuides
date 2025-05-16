# Awesome KQLs
This repository contains my Collection of Azure Resource Graph related resources such as sample scripts and Resource Graph Queries.


# ⭐ Network Security Group Rules
Query network security groups across all subscriptions expanding securityRules

```kql
Resources
| where type =~ "microsoft.network/networksecuritygroups"
| join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubcriptionName=name, subscriptionId) on subscriptionId
| mv-expand rules=properties.securityRules
| extend rule_name = tostring(rules.name)
| extend direction = tostring(rules.properties.direction)
| extend priority = toint(rules.properties.priority)
| extend access = rules.properties.access
| extend description = rules.properties.description
| extend protocol = rules.properties.protocol
| extend sourceprefix = rules.properties.sourceAddressPrefix
| extend sourceport = rules.properties.sourcePortRange
| extend sourceApplicationSecurityGroups = split((split(tostring(rules.properties.sourceApplicationSecurityGroups), '/'))[8], '"')[0]
| extend destprefix = rules.properties.destinationAddressPrefix
| extend destport = rules.properties.destinationPortRange
| extend destinationApplicationSecurityGroups = split((split(tostring(rules.properties.destinationApplicationSecurityGroups), '/'))[8], '"')[0]
| extend subnet_name = split((split(tostring(properties.subnets), '/'))[10], '"')[0]
| project SubcriptionName, resourceGroup, subnet_name, name, rule_name, direction, priority, access, description, protocol, sourceport, sourceprefix, sourceApplicationSecurityGroups, destport, destprefix, destinationApplicationSecurityGroups
| sort by SubcriptionName, resourceGroup, name asc, direction asc, priority asc
```



# ⭐ Role Assignments
List all Owner Role Assignments by subscriptions including inherited assignments

```kql
resourcecontainers
| where type =~ 'microsoft.resources/subscriptions'
| extend  mgParent = properties.managementGroupAncestorsChain
| extend subScope = pack_array(subscriptionId)
| extend rootScope = pack_array('/')
| extend scopes=array_concat(mgParent, subScope, rootScope)
| mv-expand scopes
| extend  scopeName=iff(isempty(tostring(scopes.name)), tostring(scopes), scopes.name)
| project subscriptionId, name, scopes, scopeName
| join kind=inner (
    authorizationresources
    | where type =~ 'microsoft.authorization/roleAssignments'
    | extend roleDefinitionId = properties.roleDefinitionId
    | where roleDefinitionId =~ '/providers/Microsoft.Authorization/RoleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
    | extend scope = tostring(properties['scope'])
    | extend mgOrRootScope = iff(scope =='/', scope, (tostring((split(scope, '/', 4))[0])))
    | extend scopeName = iff(isempty(mgOrRootScope), subscriptionId, mgOrRootScope)
    | extend principalType = tostring(properties['principalType'])
    | extend principalId = tostring(properties['principalId'])
    | project id, principalId, principalType, scope, scopeName, roleDefinitionId
) on $left.scopeName == $right.scopeName
| project id, subscriptionName = name, scope, roleDefinitionId, principalType, principalId, scopeName
| summarize count() by subscriptionName
```


# ⭐ General Azure KQLs
The kusto query below is using the new ResourceChanges resource, and will give you a list of all changes made in your Azure environment, create, update, delete, automatic or manual, it will all be there. (Where you have access).
This is a great way to keep track of what is happening in and to your environment.

```kql
ResourceChanges
| join kind=inner
   (resourcecontainers
   | where type == 'microsoft.resources/subscriptions'
   | project subscriptionId, subscriptionName = name)
   on subscriptionId
| extend changeTime = todatetime(properties.changeAttributes.timestamp), targetResourceId = tostring(properties.targetResourceId),
changeType = tostring(properties.changeType), correlationId = properties.changeAttributes.correlationId,
changedProperties = properties.changes, changeCount = properties.changeAttributes.changesCount
| extend resourceName = tostring(split(targetResourceId, '/')[-1])
| extend resourceType = tostring(split(targetResourceId, '/')[-2])
| where changeTime > ago(7d)
// Change the time span as preferred, 1d(1 day/24h), 7d, 30d...
| where subscriptionName contains "" // "" for all subscriptions
| order by changeType asc, changeTime desc
// Change what you sort by as prefered, type, time, subscriptionName, etc.
| project changeTime, resourceName, resourceType, resourceGroup, changeType, subscriptionName, subscriptionId, targetResourceId, 
correlationId, changeCount, changedProperties
```