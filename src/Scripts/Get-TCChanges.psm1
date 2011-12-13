function Get-TCChanges{
<#
.SYNOPSIS
    Returns all source control changes included between the latest two TeamCity pinned builds for a given TeamCity project and build configuration
.DESCRIPTION
    Returns all source control changes included between the latest two TeamCity pinned builds for a given TeamCity project and build configuration
.NOTES
    Name: Get-TCChanges
    Author: Lloyd Holman
    DateCreated: 13/12/2011
.EXAMPLE
    Get-ReleaseChanges "AutoBot"
Description
------------
Returns a list of source control changes included between the latest two TeamCity pinned builds for the TeamCity project named "AutoBot" 
with a default buildType (build configuration) name "1_Build". 

#>
[cmdletbinding()]
    Param(
        [Parameter(
			Position = 0,
            Mandatory = $True )]
            [string]$tcprojectname,
		[Parameter(
			Position = 1,
            Mandatory = $False )]
            [string]$tcbuildtypename,
		[Parameter(
			Position = 2,
            Mandatory = $False )]
            [string]$tcserver,
		[Parameter(
			Position = 3,
            Mandatory = $False )]
            [string]$tcusername,
		[Parameter(
			Position = 4,
            Mandatory = $False )]
            [string]$tcpassword
        )
Begin {
		$DebugPreference = "Continue"
    }	
Process {
			Try 
			{
				if ($tcserver -eq "")
				{
					$tcserver = "teamcity.codebetter.com"
				}
				if ($tcbuildtypename -eq "")
				{
					$tcbuildtypename = "1_Build"
				}
				
				$teamCitySharp = Add-Type -Path "..\TeamCitySharp.dll"
				$tcClient = New-Object -TypeName TeamCitySharp.TeamCityClient -ArgumentList $tcserver
				
				if ($tcusername -eq "" -and $tcpassword -eq "")
				{
					Write-Debug "Connecting to TeamCity with guest account"
					$tcClient.Connect($null,$null,$True)
				}
				else
				{
					Write-Debug "Connecting to TeamCity using username: '$($tcusername)'"
					$tcClient.Connect($tcusername,$tcpassword)
				}
				
				$buildConfig = $tcClient.BuildConfigByProjectNameAndConfigurationName($tcprojectname, $tcbuildtypename)
				Write-Debug "1. Found build configuration by selected project name: '$($tcprojectname)' and build configuration name: '$($tcbuildtypename)'"
				
				$pinnedBuilds = $tcClient.BuildsByBuildLocator([TeamCitySharp.BuildLocator]::WithDimensions([TeamCitySharp.BuildTypeLocator]::WithId($buildConfig.Id), $null, $null, [TeamCitySharp.BuildStatus]::SUCCESS, $false, $false, $false, $true, 2, $null, $null, $null));
				Write-Debug "2. Found the latest 2 pinned builds by build configuration id: '$($buildConfig.Id)', status: SUCCESS"
				
				$youngestPinnedBuildChanges = $tcClient.ChangesByBuildId($pinnedBuilds[0].Id)
				$oldestPinnedBuildchanges = $tcClient.ChangesByBuildId($pinnedBuilds[1].Id)
				Write-Debug "3. Retrieved '$($youngestPinnedBuildChanges.Count)' (youngest pinned build) and '$($oldestPinnedBuildchanges.Count)' (oldest pinned build) changes in the last 2 pinned builds"
				
				$changesBetween = $tcClient.ChangesByConfigurationIdAndSinceChangeId($buildConfig.Id, $oldestPinnedBuildchanges[$oldestPinnedBuildchanges.Count - 1].Id)
				$changesBetween.Add($tcClient.ChangeDetailsByChangeId($oldestPinnedBuildchanges[$oldestPinnedBuildchanges.Count - 1].Id))
				Write-Debug "4. Retrieved a total of '$($changesBetween.Count)' changes since the oldest change in the oldest pinned build (up to and including the most recent change in the project)"
			
				$youngestChangeId = $youngestPinnedBuildChanges[0].Id
				while ([System.Int32]::Parse($changesBetween[0].Id) -gt [System.Int32]::Parse($youngestChangeId)) 
					{ $changesBetween.RemoveAt(0); Write-Debug "? '$($changesBetween[0].Id)' > '$($youngestChangeId)'" }
				
				Write-Debug "5. Filtered out changes made since change id: '$($youngestChangeId)' (the most recent change in the most recent pinned build)"
				
				$result = @()
				foreach ($change in $changesBetween)
				{
					#TeamCitySharp doesn't support enriched Change details yet so we need to retrieve them.
					$changeWithDetail = $tcClient.ChangeDetailsByChangeId($change.Id)
					$result += ,@{"Id" = $change.Id; "Username" = $changeWithDetail.Username; "Comment" = $changeWithDetail.Comment; "Date" = $changeWithDetail.Date}
				}
				Write-Debug "6. Retrieved change details for each change and formatted output"
				

			}
			catch [System.Net.WebException]{
				$result = "$tcserver is not a valid servername, please be sure to use the FQDN:port where necessary." 
			}
			catch [Exception] {
				$result = "Woh!, wasn't expecting to get this exception. `r`n $_.Exception.ToString()"
			}
    }
End {
		return $result | Format-Table 
    }
}

