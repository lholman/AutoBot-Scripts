function Get-ReleaseChanges{
<#
.SYNOPSIS
    Returns all source control changes included between the latest two TeamCity pinned builds for a given TeamCity project and build configuration
.DESCRIPTION
    Returns all source control changes included between the latest two TeamCity pinned builds for a given TeamCity project and build configuration
.NOTES
    Name: Get-ReleaseChanges
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
		$DebugPreference = "SilentlyContinue"
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
				
				$teamCitySharp = Add-Type -Path "..\..\lib\TeamCitySharp.dll"
				$tcClient = New-Object -TypeName TeamCitySharp.TeamCityClient -ArgumentList $tcserver
				
				if ($tcusername -eq "" -and $tcpassword -eq "")
				{
					Write-Debug "Connecting to TeamCity with guest account"
					$tcClient.Connect("guest",$null,$null)
				}
				else
				{
					Write-Debug "Connecting to TeamCity using username: '$($tcusername)'"
					$tcClient.Connect($tcusername,$tcpassword)
				}
				
				$buildConfig = $tcClient.BuildConfigByProjectNameAndConfigurationName($tcprojectname, $tcbuildtypename)
				Write-Debug "1. Found build configuration by selected project name: '$($tcprojectname)' and build configuration name: '$($tcbuildtypename)'"
				
				$pinnedBuilds = $tcClient.BuildsByBuildLocator([TeamCitySharp.BuildLocator]::WithDimensions([TeamCitySharp.BuildTypeLocator]::WithId($buildConfig.Id), $null, $null, [TeamCitySharp.BuildStatus]::SUCCESS, $false, $false, $false, $true, 2, $null, $null, $null, $null));
				if ([System.Int32]::Parse($pinnedBuilds.Count) -ne 2)
				{
					Write-Debug "Unable to find 2 pinned builds for project name: '$($tcprojectname)' and build configuration name: '$($tcbuildtypename)'"
					break;
				}
				Write-Debug "2. Found the latest '$($pinnedBuilds.Count)' pinned builds by build configuration id: '$($buildConfig.Id)' and status: SUCCESS"
				
				$buildId = $pinnedBuilds[0].Id
				Write-Debug "3. Retrieving most recent pinned build (buildId: '$($buildId)') change information..."
				$mostRecentBuildChanges = $tcClient.ChangesByBuildId($buildId)
				if ($mostRecentBuildChanges.Count -eq $null)
				{
					Write-Debug "The mostRecent pinned build has no changes"
					#1. Move to the next mostRecent build and look for the most recent change
				}
				Write-Debug "3. Most recent calculated build (buildId: '$($buildId)') with changes has '$($mostRecentBuildChanges.Count)' change(s)"
				
				$buildId = $pinnedBuilds[1].Id
				Write-Debug "4. Retrieving next oldest pinned build (buildId: '$($buildId)') change information..."
				$changeCount = 0
				$i = 0
				while ($changeCount -le 0)
				{
					if ($i -ge 1)
					{
						Write-Debug "BuildId: '$($buildId)' has no changes, retrieving the next most recent build..."
						$moreRecentBuilds = $tcClient.BuildsByBuildLocator([TeamCitySharp.BuildLocator]::WithDimensions(
																	[TeamCitySharp.BuildTypeLocator]::WithId($buildConfig.Id), $null, $null, [TeamCitySharp.BuildStatus]::SUCCESS, $false, $false, $false, $null, $null, $null, [TeamCitySharp.BuildLocator]::WithId($buildId), $null, $null ));				
						
						$buildId = $moreRecentBuilds[$moreRecentBuilds.Count - 1].Id
					}
					#1. Move to the next most recent build and check for changes
					$oldestBuildChanges = $tcClient.ChangesByBuildId($($buildId))
					if ($oldestBuildchanges.Count -ne $null)
					{
						$changeCount = [System.Int32]::Parse($oldestBuildchanges.Count)
					}
					$i++
				}
				Write-Debug "4. Oldest calculated build (buildId: '$($buildId)') with changes has '$($oldestBuildchanges.Count)' change(s)"

				$changesBetween = $tcClient.ChangesByConfigurationIdAndSinceChangeId($buildConfig.Id, $oldestBuildChanges[$oldestBuildChanges.Count - 1].Id)
				$changesBetween.Add($tcClient.ChangeDetailsByChangeId($oldestBuildChanges[$oldestBuildChanges.Count - 1].Id))
				Write-Debug "4. Retrieved a total of '$($changesBetween.Count)' changes since the oldest change in the oldest build (up to and including the most recent change in the project)"
			
				$mostRecentChangeId = $mostRecentBuildChanges[0].Id
				
				while ([System.Int32]::Parse($changesBetween[0].Id) -gt [System.Int32]::Parse($mostRecentChangeId)) 
					{ $changesBetween.RemoveAt(0); Write-Debug "? '$($changesBetween[0].Id)' > '$($mostRecentChangeId)'" }
				
				Write-Debug "5. Filtered out changes made since change id: '$($mostRecentChangeId)' (the most recent change in the most recent build)"
				
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
			catch [Exception]{
				$result = "Woh!, wasn't expecting to get this exception. `r`n $($_.ToString())"
			}
    }
End {
		return $result | Format-Table 
    }
}

