<#
	.SYNOPSIS
	Installs prerequisites for scripts.
	
	.DESCRIPTION
	Installs prerequisites for scripts.

	.INPUTS
	None.

	.OUTPUTS
	None.

	.EXAMPLE
	PS> .\Install-Scripts
#>
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param ([Parameter()] [switch] $UpdateHelp,
	   [Parameter(Mandatory = $true)] [string] $ModulesPath)

Begin
{
	$script = $MyInvocation.MyCommand.Name
	if(-Not (Test-Path ".\$script"))
	{
		Write-Host "Installation must be run from the same directory as the installer script."
		exit
	}

	if(-Not (Test-Path $ModulesPath))
	{
		Write-Host "'$ModulesPath' was not found."
		exit
	}

	$Env:PSModulePath += ";$ModulesPath"
	
	if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Start-Process -FilePath "pwsh.exe" -ArgumentList "-File `"$PSCommandPath`"", "-ModulesPath `"$ModulesPath`"" -Verb RunAs
		exit
	}
}

Process
{	
	Add-PathToProfile -PathVariable 'Path' -Path (Get-Location).Path
	Add-PathToProfile -PathVariable 'PSModulePath' -Path $ModulesPath
	
	Add-AliasToProfile -Script 'Get-FactorioModsHelp' -Alias 'gfmh'
	Add-AliasToProfile -Script 'Get-FactorioModsHelp' -Alias 'fmhelp'
	Add-AliasToProfile -Script 'Build-FactorioMod' -Alias 'bfm'
	Add-AliasToProfile -Script 'Build-FactorioMod' -Alias 'fmbd'
	Add-AliasToProfile -Script 'Open-FactorioLog' -Alias 'ofl'
	Add-AliasToProfile -Script 'Open-FactorioLog' -Alias 'fmol'
	Add-AliasToProfile -Script 'Set-FactorioModDirectory' -Alias 'sfmd'
	Add-AliasToProfile -Script 'Set-FactorioModDirectory' -Alias 'fmsd'
}

End
{
	Format-Profile
	Complete-Install
}