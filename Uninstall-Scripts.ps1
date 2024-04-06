<#
	.SYNOPSIS
	Uninstalls prerequisites for scripts.
	
	.DESCRIPTION
	Uninstalls prerequisites for scripts.

	.INPUTS
	None.

	.OUTPUTS
	None.

	.EXAMPLE
	PS> .\Uninstall-Scripts
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
	Remove-PathFromProfile -PathVariable 'Path' -Path (Get-Location).Path
	
	Remove-AliasFromProfile -Script 'Get-FactorioModsHelp' -Alias 'gfmh'
	Remove-AliasFromProfile -Script 'Get-FactorioModsHelp' -Alias 'fmhelp'
	Remove-AliasFromProfile -Script 'Build-FactorioMod' -Alias 'bfm'
	Remove-AliasFromProfile -Script 'Build-FactorioMod' -Alias 'fmbd'
	Remove-AliasFromProfile -Script 'Open-FactorioLog' -Alias 'ofl'
	Remove-AliasFromProfile -Script 'Open-FactorioLog' -Alias 'fmol'
	Remove-AliasFromProfile -Script 'Set-FactorioModDirectory' -Alias 'sfmd'
	Remove-AliasFromProfile -Script 'Set-FactorioModDirectory' -Alias 'fmsd'
}

End
{
	Format-Profile
	Complete-Install
}