### Spot-Jira Module

We use this module to create [Atlassian Jira tickets](https://www.atlassian.com/software/jira/) when we perform some actions with our [UnusedServers PowerShell module](https://github.com/spottradingllc/unused-servers). This module reuqires [Spot-Graphite PowerShell module](https://github.com/spottradingllc/Spot-Graphite)

### Installation

1. Determine PowerShell modules directory you want to use (type `$env:PSModulePath` and chose one, for example `c:\Windows\system32\WindowsPowerShell\v1.0\Modules`).
2. Download repo and place all files under Modules directory you chose in the first step into `Spot-Jira` folder (`c:\Windows\system32\WindowsPowerShell\v1.0\Modules\Spot-Jira`).
3. Make sure the files are not blocked. Right click on the files and un-block them by going into properties.
4. Make sure to set your PowerShell Execution Policy to `RemoteSigned`, for example `Set-ExecutionPolicy RemoteSigned -Force`.
5. Type `Get-Module -ListAvailable` and make sure you see Spot-Jira module in the list

### Usage

`help Get-Jira -Detailed`

### Examples

`Get-Jira -CreateTicket -Assignee test.user -ProdDate (Get-Date) -Summary "Test" -Description "Test. Delete"` - creates Jira ticket

`Get-Jira -GetTicket DEV-4740` - gets information about DEV-4740 ticket

`Get-Jira` - displays all Jira ticket for today's date

`Get-Jira -SearchDate 10/6/2015` - displays all Jira tickets for specified date

`Get-Jira -Validate DEV-4740` - validates Jira ticket

`Get-Jira -CloseTicket DEV-4740` - closes Jira ticket

`Get-Jira -Delete DEV-4740` - deletes Jira ticket

`Get-Jira -Quiet -Graphite` - will send Jira ticket counts per project and project names to Graphite.


