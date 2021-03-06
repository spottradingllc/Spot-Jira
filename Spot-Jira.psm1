$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$JiraConfigPath = [string](Split-Path -Parent $MyInvocation.MyCommand.Definition) + '\Spot-Jira-config.xml'

# Internal Functions
. $here\Functions\Read-JiraConfig.ps1

# User facing functions
. $here\Functions\Get-Jira.ps1
. $here\Functions\Get-CountSameInArray.ps1