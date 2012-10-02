Remove-Module Get-ReleaseChanges
Import-Module .\Get-ReleaseChanges.psm1
Get-ReleaseChanges -tcprojectname AutoBot -tcserver localhost:771
