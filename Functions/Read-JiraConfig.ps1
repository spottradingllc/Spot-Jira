Function Read-JiraConfig {

		Param (
	    
        [Parameter(Mandatory = $true)]
        $Path
    )

	Try {
	
		$Config = @{}
			
		$xmlconfig = [xml]([System.IO.File]::ReadAllText($Path))

		[string]$JiraName = $xmlconfig.Configuration.JiraServerName
		[string]$ProjectKey = $xmlconfig.Configuration.ProjectKey
		[string]$ProjectName = $xmlconfig.Configuration.ProjectName

		[string]$graphiteStagingDNSAlias = $xmlconfig.Configuration.Graphite.StagingAlias
		[string]$graphiteUATDNSAlias = $xmlconfig.Configuration.Graphite.UATAlias
		[string]$graphiteProductionDNSAlias = $xmlconfig.Configuration.Graphite.ProductionAlias
		[string]$graphitePathPrefix = $xmlconfig.Configuration.Graphite.PathPrefix
	
		[string]$JiraAuth = $xmlconfig.Configuration.JiraAuth
		
		$Config.JiraName = $JiraName
		$Config.ProjectKey = $ProjectKey
		$Config.ProjectName = $ProjectName
			
		$Config.graphiteStagingAlias = $graphiteStagingDNSAlias
		$Config.graphiteUATAlias = $graphiteUATDNSAlias
		$Config.graphiteProductionAlias = $graphiteProductionDNSAlias
		$Config.graphitePathPrefix = $graphitePathPrefix
			
		$Config.JiraAuth = $JiraAuth
		
		Return $Config
	}
	
	Catch { $_ ; break }

}