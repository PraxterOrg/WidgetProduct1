
## PowerShell 
# This my example of the how to create team, repros and branches. 
# protection policies were also experimented
# I used the github for powershell
# This was super helpful and put together good
# I also had a chance to see how the rest API would work 

## Variables ##
$myOrg = "PraxterOrg"

Install-Module -Name PowerShellForGitHub

# called the Set-GitHubAuthentication that had me put in the username password which then cached it. Enter the Token for the password and the whatever for the usnername.
# keyvault would be a good ADD, maybe not MVP.
#Set-GitHubAuthentication  

$secureString = ("GetFromKeyVault" | ConvertTo-SecureString -AsPlainText -Force)
$cred = New-Object System.Management.Automation.PSCredential "username is ignored", $secureString
Set-GitHubAuthentication -Credential $cred


#Set-GitHubConfiguration -DefaultOwnerName PowerShell ## these are for the user of default
#Set-GitHubConfiguration -DefaultRepositoryName PowerShellForGitHub ## this is the repro default 

#$issues = Get-GitHubIssue -Uri 'https://github.com/praxterorg/base' ## get issues from a repro

#New-GitHubRepository -RepositoryName $myExampleNewRepro -Organization $myOrg -DisallowRebaseMerge  ## looks like error if it exists (write code for error handling)
#$repro = Get-GitHubRepository -OwnerName $myOrg -RepositoryName $myExampleNewRepro
#$repro | remove-GitHubRepos
## need to configure a template repro ## 

##Set-GitHubRepositoryTeamPermission this should be used in the template to for base memeberships  
##Get-GitHubRepositoryTeamPermission should be used for audit features

## This will create a Team of developers if ieam -OrganizationName $t doesnt exists 
## here is the my first block

## this line is to reset the team and delete it if needed. 
<#
Remove-GitHubTeam -Organization $myOrg -TeamName IT -Confirm:$false -ErrorAction SilentlyContinue
Remove-GitHubTeam -Organization $myOrg -TeamName TeamAdmin -Confirm:$false -ErrorAction SilentlyContinue
Remove-GitHubTeam -Organization $myOrg -TeamName TeamMaintain -Confirm:$false -ErrorAction SilentlyContinue
Remove-GitHubTeam -Organization $myOrg -TeamName TeamReader -Confirm:$false -ErrorAction SilentlyContinue
Remove-GitHubTeam -Organization $myOrg -TeamName TeamWrite -Confirm:$false -ErrorAction SilentlyContinue
Remove-GitHubRepository -OwnerName $myOrg -RepositoryName WidgetProduct1 -Confirm:$false -ErrorAction SilentlyContinue

#>
Function New-GitHubTeamFromArray {  
    [CmdletBinding()] param (
        [Parameter()] [string] $teamName,
        [Parameter()] [string] $Description,
        [Parameter()] [string] $privacy,
        [Parameter()] [string] $ParentTeamName
        )
try {Get-GitHubTeam -OrganizationName $myOrg -TeamName $teamName}catch {New-GitHubTeam -OrganizationName $myOrg -TeamName $teamName}
finally {Set-GitHubTeam -OrganizationName $myOrg -TeamName $teamName -description $teamDescription -privacy $privacy -ParentTeamName $parentTeamName}
} 

Function New-GitReproFromArray {  
    [CmdletBinding()] param (
        [Parameter()] [string] $reproName,
        [Parameter()] [string] $Description,
        [Parameter()] [string] $privacy,
        [Parameter()] [string] $defaultBranch,
        [Parameter()] [string] $TeamID,
        [Parameter()] [string] $OwnerName
    )
    
    try {get-GitHubRepository -RepositoryName $reproName -OwnerName $myOrg}
    catch {
        write-host "error"
        new-GitHubRepository -RepositoryName $reproName -Organization $myOrg -TeamId $TeamID -AutoInit
    }
    finally {
        Set-GitHubRepository -RepositoryName $reproName -Description $Description -OwnerName $myOrg 
     }
}

Function Get-GitHubTeamID {
    [CmdletBinding()] param (
        [Parameter()] [string] $teamName
    )
    Try {
        $MyTeamID = (Get-GitHubTeam -OrganizationName $myOrg -TeamName $teamName).TeamID
        return $MyTeamID}
    Catch {Write-host "error "}
}

Function Set-GitHubTeamPerms {
    [CmdletBinding()] param (
        [Parameter()] [string] $teamName,
        [Parameter()] [string] $Repro,
        [Parameter()] [string] $Permissions

    )
    Try {
        Set-GitHubRepositoryTeamPermission -OwnerName $myOrg -RepositoryName $Repro -TeamName $teamName -Permission $Permissions }
        
    Catch {
        Write-host "error " -ErrorAction stop   
      }
}

## Enable Dependabot Security ## 
## Per Repro or Pre Org
## Trying to loop throug the json file

## setup the teams 
$JsonDataObject =Get-Content -Path "C:\GIT\Experiment\data.json" | ConvertFrom-Json
foreach ($Name in $JsonDataObject.Teams) 
{
    New-GitHubTeamFromArray -teamName ($Name.TeamName) -Description ($Name.Properties.Description) -privacy ($Name.Properties.Privacy) -ParentTeamName ($Name.Properties.ParentTeamNamearentTeamName)
    Write-host "The teams name "+$Name.TeamName
    ## I need to add memebers for sure ##
}     

foreach ($Repro in $JsonDataObject.Repro) 
{ 
    write-host "Processing Repro "+$Repro.reproName
    $MyTeamID = (Get-GitHubTeamID -teamName ($Repro.properties.teamName))
    New-GitReproFromArray -reproName ($Repro.reproName) -TeamId $MyTeamID


    foreach ($TeamName in $JsonDataObject.Teams) 
    {
        foreach ($TeamProperties in $TeamName.Properties.Permissions) {
            Write-host ("The ReproName is "+$Repro.reproName+" with the teamname of "+$TeamName.TeamName+" and permissions to "+$TeamProperties)
            Set-GitHubRepositoryTeamPermission -OwnerName $myOrg -RepositoryName ($Repro.reproName) -TeamName ($TeamName.TeamName) -Permission $TeamProperties    
        }
    }

}

Write-Host "************************ Completed Work Making Objects **************************"
$ReproResults = (Get-GitHubRepository -OwnerName praxterorg -RepositoryName WidgetProduct)

$ArgProtectionPolicys = @{cat = "sda"}

#$ProtectionPolicy = ($Branch |new-GitHubRepositoryBranchPatternProtectionRule @ArgProtectionPolicys)
$URIOrg ="https://api.github.com/orgs/PraxterOrg)"
$URIRepo = "https://api.github.com/repos/PraxterOrg/WidgetProduct1/branches"

#$Request = (Invoke-webrequest -H  @{'Accept'= 'application/vnd.github.v3+json'} -uri $URIRepo)
#$Request.Content |Write-Output |ConvertFrom-Json


$Branch |Get-GitHubRepositoryBranchProtectionRule 
$Branch |Remove-GitHubRepositoryBranchProtectionRule

$branch |New-GitHubRepositoryBranchProtectionRule 



