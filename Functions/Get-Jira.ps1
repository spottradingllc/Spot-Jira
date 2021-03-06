Function Get-Jira {

<#

.Synopsis

Get-Jira allows creation, deletion, searching, approving and closing of Infrastructure change orders in Jira.

.Description

Get-Jira uses Jira REST API to manipulate status of Infrastructure change orders in Jira. It allows you to create ticket, change tickets transition state (approved, deployed, close), delete ticket 
or you can search for specific ticket to display short summary. You can also search for all change orders in a particular date.

Get-Jira also supports Quite parameter so it can be used within the scripts to automatically create tickets, deploy and close them on success of your script (or delete if the script did not run successfully).

Get-Jira also allows to send all changes to Graphite with -Quiet Yes and -Graphite Yes options. 

.Parameter CreateTicket

Creates Jira ticket. It requires other parameters to be specified, like Summary, Description, Assignee and ProdDate.

.Parameter Summary

Quick summary of the change you are performing. This parameter can only be used if -CreateTicket Yes.

.Parameter Description

Description of your change. Provide more details than in Summary. This parameter can only be used if -CreateTicket Yes.

.Parameter Assignee

Person who this ticket should be assigned to. Please keep the same spelling of the user as in Active Directory (most users will be first.last format). This parameter can only be used if -CreateTicket Yes.

.Parameter ProdDate

Date of the change (defaults to current date if not specified). Use DD/MM/YYYY or DD-MM-YYYY format. This parameter can only be used if -CreateTicket Yes.

.Parameter DeleteTicket

Allows you to delete ticket. Make sure you spell ticket name correctly (like you see in Jira - ITINFRA-23 DAT-384 etc.)

.Parameter GetTicket

Allows you to display short information about the specified ticket. Make sure you spell ticket name correctly (like you see in Jira - ITINFRA-23 DAT-384 etc.)

.Parameter ApproveTicket

Allows you to approve ticket. Make sure you spell ticket name correctly (like you see in Jira - ITINFRA-23 DAT-384 etc.)

.Parameter DeployTicket

Allows you to deploy ticket to Production. Make sure you spell ticket name correctly (like you see in Jira - ITINFRA-23 DAT-384 etc.)

.Parameter CloseTicket

Allows you to close the ticket. Make sure you spell ticket name correctly (like you see in Jira - ITINFRA-23 DAT-384 etc.)

.Parameter SearchDate

Allows you to specify the date to display all changes for. Use DD/MM/YYYY or DD-MM-YYYY format. Defaults to current date if not specified.

.Parameter Quiet

Useful when is called from another script. It will not display any information but rather return True or False on success or failure.

.Parameter Graphite

Can only be used with -SearchDate and -Quiet Yes parameters. Sends information to Graphite.

.Example

Get-Jira

Will display all changes for the current date.

.Example

Get-Jira -CreateTicket -Assignee "test.user" -Description "Testing the ability to create Jira ticket by using REST API" -Summary "Testing Jira REST API" -ProdDate "10/01/2015"

Will create Infrastructure change order in Jira for 10/01/2015 with the given Summary and Description. The ticket will be assigned to Test User.
It will return change order name (like ITINFRA-1292).

.Example

Get-Jira -ApproveTicket ITINFRA-1292

Approve ITINFRA-1292 change order.

.Example

Get-Jira -DeployTicket ITINFRA-1292

Deploy ITINFRA-1292 change order.

.Example

Get-Jira -CloseTicket ITINFRA-1292 -Quiet

Close ITINFRA-1292 ticket. It will not display any information but rather return True on Success or False on Failure. Useful within other scripts.

.Example

Get-Jira -DeleteTicket ITINFRA-1292

Delete ITINFRA-1292 ticket.

.Example

Get-Jira -SearchDate 1/15/2014

Search and display all change orders for 1/15/2014.

.Example

Get-Jira -SearchDate 1/15/2014 -Quite -Graphite

Search and display all change orders for 1/15/2014, do not display any output and send information about change orders to graphite.

#>

[CmdletBinding(SupportsShouldProcess = $false, DefaultParameterSetname = "Nothing", ConfirmImpact="Medium")] 

Param (

	[Parameter(ParameterSetName = "Create", Mandatory = $true)]
	[switch]
	$CreateTicket,
	
	[Parameter(ParameterSetName = "Delete", Mandatory = $true)]
	[string]
	$DeleteTicket,
	
	[Parameter(ParameterSetName = "Create", Mandatory = $true)]
	[string]
	$Summary,
	
	[Parameter(ParameterSetName = "Create", Mandatory = $true)]
	[string]
	$Description,
	
	[Parameter(ParameterSetName = "Create", Mandatory = $true)]
	[string]
	$Assignee,
	
	[Parameter(ParameterSetName = "Create", Mandatory = $true)]
	[string]
	[ValidatePattern("(\d{1,2})[/-](\d{1,2})[/-](\d{4})")]
	$ProdDate = (Get-Date).ToShortDateString(),
	
	[Parameter(ParameterSetName = "Get", Mandatory = $true)]
	[string]
	$GetTicket,
	
	[Parameter(ParameterSetName = "Start", Mandatory = $true)]
	[string]
	$StartProgress,
	
	[Parameter(ParameterSetName = "Stop", Mandatory = $true)]
	[string]
	$StopProgress,
	
	[Parameter(ParameterSetName = "Validate", Mandatory = $true)]
	[string]
	$Validate,	
	
	[Parameter(ParameterSetName = "Close", Mandatory = $true)]
	[string]
	$CloseTicket,
	
	[Parameter(ParameterSetName = "Search")]
	[string]
	[ValidatePattern("(\d{1,2})[/-](\d{1,2})[/-](\d{4})")]
	$SearchDate = (Get-Date).ToShortDateString(),
	
	[Parameter(ParameterSetName = "Quiet", Mandatory = $true)]
	[Parameter(ParameterSetName = "Create")]
	[Parameter(ParameterSetName = "Delete")]
	[Parameter(ParameterSetName = "Get")]
	[Parameter(ParameterSetName = "Start")]
	[Parameter(ParameterSetName = "Close")]
	[Parameter(ParameterSetName = "Search")]
	[Parameter(ParameterSetName = "Stop")]
	[Parameter(ParameterSetName = "Validate")]
	[switch]
	$Quiet,
	
	[Parameter(ParameterSetName = "Search", Mandatory = $false)]
	[switch]
	$Graphite
		
)

Begin {

	$ErrorActionPreference = "Stop"
	
	If ( $PSBoundParameters.Count -eq 0 -or ( $PSBoundParameters['Quiet'] -match $true -and $PSBoundParameters['Graphite'] -match $true ) ) {
	
		$PSBoundParameters['SearchDate'] = (Get-Date).ToShortDateString()
	
	}
	
	$Config = Read-JiraConfig -Path $JiraConfigPath
	
	$JiraServerName = $Config.JiraName
	$JiraAuth = $Config.JiraAuth
	
	$ProjectKey = $Config.ProjectKey
	$ProjectName = $Config.ProjectName
	
	$GraphiteStaging = $Config.graphiteStagingAlias
	$GraphiteUAT = $Config.graphiteUATAlias
	$GraphiteProduciton = $Config.graphiteProductionAlias
	$GraphitePathPrefix = $Config.graphitePathPrefix

	$BaseURI = "http://$($JiraServerName):8080"

	# Prepopulating with IT_Jira_Automation user credentials (you can guess the password :-))
	$Headers = @{ "Authorization" = "$JiraAuth" }
	
	# To get available transitions: Invoke-WebRequest -uri "http://<JiraServerName>:8080/rest/api/2/issue/<ProjectName>-2174/transitions" -Headers $headers -ContentType "application/json" -Method Get -TimeoutSec 10
	

	Function ConvertDate ( $DateToConvert ) {
	
		$Date = Get-Date $DateToConvert

		$Year = $Date.Year

		$Month = $Date.Month

		$Day = $Date.Day

		$Date = "$Year-$Month-$Day"
		
		return $Date
	
	}
	
	Function Ticket-Operations ( $Issue, $Operation ) {
			
		$Uri = "$BaseURI/rest/api/2/issue/$Issue"
		
		$global:Result = Invoke-WebRequest -uri $uri -Headers $headers -ContentType "application/json" -Method $Operation -TimeoutSec 10
		
		return $Result.StatusCode

	}
	
	Function Create-Ticket ( $Body ) {
	
		$Uri = "$BaseURI/rest/api/2/issue/"
	
		$Result = Invoke-WebRequest -uri $uri -Headers $headers -ContentType "application/json" -Method POST -Body $Body -TimeoutSec 15
		
        $Result = $Result.Content | ConvertFrom-Json

        $Key = $Result.key

        return $Key 		

	}
	
	
	Function Transition-Ticket ( $id ) {

$Body = @"
{
    "transition": { 
  		"id":  "$id"
	}
}
"@
		$Uri = "$BaseURI/rest/api/2/issue/$Issue/transitions"

		$Result = Invoke-WebRequest -uri $uri -Headers $headers -ContentType "application/json" -Method Post -Body $Body -TimeoutSec 10
	
		return $Result.StatusCode

	}
	
	Function Search-Jira ( $Search ) {
	
		$Uri = "$BaseURI/rest/api/2/search?jql=" + $Search

		$SearchResult = Invoke-WebRequest -uri $uri -Headers $headers -ContentType "application/json" -Method Get -TimeoutSec 10
		
		return $SearchResult
		
	}
	
} #End Begin

Process {

	#Error handling
		trap {
	
			If ($_.Exception.Message -match "404") {
			
				If ( $Quiet ) { $False }
			
				Else {
				
					""
			
					Write-Host "Please verify that $Issue is correctly spelled!" -BackgroundColor Red -ForegroundColor Yellow 
				}
		  	}
			
			ElseIf ($_.Exception.Message -match "400") {
			
				If ( $Quiet ) { $False }
				
				Else {
					
					""
			
					Write-Host "Please verify that parameters are specified correctly!" -BackgroundColor Red -ForegroundColor Yellow 
					Write-Host "Make sure user exists in Jira, Production date is specified properly and you are not trying to approve already approved ticket!" -BackgroundColor Red -ForegroundColor Yellow 
				
				}
			
			}
			
			Else {
			
				If ( $Quiet ) { $False }
				
				Else {
				
					""				
					$_.Exception.Message 
				}
					
			}
																			
			continue
		}

	If ( $GetTicket ) {
	
		$Issue = $GetTicket
		
		$Operation = "GET"

		$Ticket = Ticket-Operations $Issue $Operation
		
		If ( $Ticket -match "200" ) {
		
			If ( $Quiet ) { $True }
			
			Else {
							
        		$JSON = $Result.Content | ConvertFrom-Json

        		# return $Result.fields
							
				$Result = @()
				
				$JSON.fields | % { 

					$Hash = @{}

					$Hash.Issue = $Issue
					$Hash.Summary = $_.summary
					$Hash.Project = $_.project.key
					$Hash.Status = $_.status.name
					$Hash.Environment = $_.environment
					$Hash.Description = $_.description
					$Hash.Created = Get-Date $_.created
					# This might not be closed so use $_.Updated in cases Closed is not available
					$Hash.Updated = Get-Date $_.updated
					
					$UpOrCl = "Closed"
								
					Try { $Hash.Closed = Get-Date $_.resolutiondate }
					
					Catch [System.Management.Automation.ParameterBindingException] {
										
						$UpOrCl = "Updated"	
					}
													
					Finally { 
					
						#$Hash 
					
					}
					
					$Result += New-Object PSObject -Property $Hash
									
					""
					Write-Host "$Issue Information:" -ForegroundColor Magenta
					$Result | Select Issue, Environment, Summary, Description, Status, Created, $UpOrCl | Sort  Environment, Status, Issue | fl
				}
			}
		
		}

		Else { }

	}
	
	If ( $DeleteTicket ) {
	
		$Issue = $DeleteTicket
		
		$Operation = "DELETE"

		$Ticket = Ticket-Operations $Issue $Operation
		
		If ( $Ticket -match "204" ) {
		
			If ( $Quiet ) { $True }
		
			Else { Write-Host "Deleted $Issue." -ForegroundColor Green }
		}
		
		Else {}
	}
	
	ElseIf ( $CreateTicket ) {
	
		$Date = ConvertDate $ProdDate
	
$Body = @"
{
    "fields": {
       "project":
       { 
          "key": "$ProjectKey",
		  "name": "$ProjectName"
       },
       "summary": "$Summary",
       "description": "$Description",
       "assignee": {"name": "$Assignee"},
	   "customfield_10096": "$Date",
	   "issuetype": {
          "name": "Change Order"
       }
   }
}
"@
	
		$CreatedTicket = Create-Ticket $Body
			
		return $CreatedTicket

	}
	
	ElseIf ( $StartProgress ) {
	
		$Issue = $StartProgress

  		$id =  "4" #Start Progress
	
		$U = Transition-Ticket $id
		
		If ( $U -match "204" ) {
		
			If ( $Quiet ) { $True }
			
			Else {
		
				Write-Host "Started Progress on $Issue." -ForegroundColor Green
				
			}
		
		}
		
		Else { $False }
	
	}
	
	ElseIf ( $StopProgress ) {
	
		$Issue = $StopProgress

  		$id =  "301" #Start Progress
	
		$U = Transition-Ticket $id
		
		If ( $U -match "204" ) {
		
			If ( $Quiet ) { $True }
			
			Else {
		
				Write-Host "Stopped Progress on $Issue." -ForegroundColor Green
				
			}
		
		}
		
		Else { $False }
	
	}
	
	ElseIf ( $Validate ) {
	
		$Issue = $Validate

  		$id =  "331" #Start Progress
	
		$U = Transition-Ticket $id
		
		If ( $U -match "204" ) {
		
			If ( $Quiet ) { $True }
			
			Else {
		
				Write-Host "Validated $Issue." -ForegroundColor Green
				
			}
		
		}
		
		Else { $False }
	
	}
		
	ElseIf ( $CloseTicket ) {
	
		$Issue = $CloseTicket

		$id = "2" #Close
		
		$U = Transition-Ticket $id
		
		If ( $U -match "204" ) {
		
			If ( $Quiet ) { $True }
			
			Else {
		
				Write-Host "$Issue is Closed!" -ForegroundColor Green
			
			}
		
		}
		
		Else { 

            $Error.Clear()

            $False 
            
        }
	
	}
	
	ElseIf ( $PSBoundParameters.ContainsKey('SearchDate') ) {
	
		$Date = ConvertDate $SearchDate

		$Search = "cf[10096]='$Date' or cf[10095]='$Date' or cf[10097]='$Date'&fields=summary,customfield_10095,customfield_10096,customfield_10097,project,status,environment,updated"
		
		$SearchResult = Search-Jira $Search
		
		$JSON = $SearchResult.Content | ConvertFrom-Json
		
			If ( ! $Quiet ) {
	
			$Result = @()
			
			$JSON.issues | % { 

				$Hash = @{}

				$Hash.Issue = $_.key
				$Hash.Summary = $_.fields.summary
				$Hash.Project = $_.fields.project.key
				$Hash.Status = $_.fields.status.name
				$Hash.Environment = $_.fields.environment
											
				$Result += New-Object PSObject -Property $Hash
			}

			""
			Write-Host "Changes for" $SearchDate":" -ForegroundColor Magenta
			$Result | Select Issue, Summary, Status, Environment | Sort  Environment, Status, Issue | ft -Wrap
		
		}
		
		Else {
		
			If ( $Graphite ) {
		
				$global:P = @()
		
				#For Graphite
				$JSON.issues | % { 
				
					$O = @{}

					$O.Issue = $_.key
					$O.Project = $_.fields.project.key	
					$O.Status = $_.fields.status.name
					$O.Environment = $_.fields.environment
					$O.Resolution = $_.fields.updated
				
					If ( $O.Status -match "Closed|Deployed" ) {
					
						Switch -regex ( $O.Environment ) {
						
							"Production" {
					
								$GraphiteServer = $GraphiteProduction
																		
							}
					
							"UAT" {
					
								$GraphiteServer = $GraphiteUAT
															
							}
					
							"Staging" {
					
								$GraphiteServer = $GraphiteStaging
						
							}
				
							default {
					
								$GraphiteServer = $GraphiteProduction
						
							}
										
						}
						
						$O.Graphite = $GraphiteServer
						
						$global:P += New-Object PSObject -Property $O
											
					}
				}

				$P | % {
				
					$Resolution = $_.Resolution
					$Issue = $_.Issue
					$Project = $_.Project
					$GraphiteServer = $_.Graphite
				
					#Sending snapshot start time to Graphite
					$Time = (Get-Date $Resolution).ToUniversalTime()
																						
					$Path = "$GraphitePathPrefix.$Project.$Issue.deployed"
						
					$Value = "1"
					
					#$Path
						
					Send-ToGraphite -Time $Time -CustomPath $Path -Value $Value -GraphiteServer $GraphiteServer
				
				}
			
				$UAT = $P | ? { $_.Environment -match "UAT" }

				$ProjectsUAT = $UAT.Project | Sort

				If ( $ProjectsUAT ) {

					$ResultUAT = Get-CountSameInArray -Array $ProjectsUAT

					$ResultUAT | % {

						$GraphiteServer = $GraphiteUAT
						
						$Project = $_.Item
					    $Count = $_.Count

					    $Time = $SearchDate

					    $Path = "$GraphitePathPrefix.$Project.count"

					    $Value = $Count

					    Send-ToGraphite -Time $Time -CustomPath $Path -Value $Value -GraphiteServer $GraphiteServer
							
					}
				}

				$Production = $P | ? { $_.Environment -match "Production" }

				If ( $Production ) {

					$ProjectsProduction = $Production.Project | Sort

					$ResultProduction = Get-CountSameInArray -Array $ProjectsProduction

					$ResultProduction | % {

						$GraphiteServer = $GraphiteProduction
						
						$Project = $_.Item
					    $Count = $_.Count

					    $Time = $SearchDate

					    $Path = "$GraphitePathPrefix.$Project.count"

					    $Value = $Count

					    Send-ToGraphite -Time $Time -CustomPath $Path -Value $Value -GraphiteServer $GraphiteServer
							
					}
				}

				$Staging = $P | ? { $_.Environment -match "Staging" }

				If ( $Staging ) {

					$ProjectsStaging = $Staging.Project | Sort

					$ResultStaging = Get-CountSameInArray -Array $ProjectsStaging

					$ResultStaging | % {

						$GraphiteServer = $GraphiteStaging
						
						$Project = $_.Item
					    $Count = $_.Count

					    $Time = $SearchDate

					    $Path = "$GraphitePathPrefix.$Project.count"

					    $Value = $Count

					    Send-ToGraphite -Time $Time -CustomPath $Path -Value $Value -GraphiteServer $GraphiteServer
							
					}

				}
			
			}
			
			Else { }
		}
	}
	
	Else { }
	

} # End Process

End {

    $Error.Clear()
    $global:Body = $null
    $global:Issue = $null
    $global:Ticket = $null
    $global:Date = $null
	$global:Result = $null
	$global:SearchDate = $null
}

}