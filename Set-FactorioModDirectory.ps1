<#
	.SYNOPSIS
	Changes to a Factorio mod directory.
	
	.DESCRIPTION
	Changes to a Factorio mod directory.

	.PARAMETER Extract
	Whether the mod package should be extracted.
	
	.INPUTS
	None.

	.OUTPUTS
	None.

	.EXAMPLE
	PS> .\Set-FactorioModDirectory.ps1 -Extract
#>
using module Varan.PowerShell.Validation
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.0
#Requires -Modules Varan.PowerShell.Validation
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
param (	
		[Parameter]	[switch]$Extract
	  )
DynamicParam { Build-BaseParameters -IncludeMusicPathQueues }

Begin
{	
	Write-LogTrace "Execute: $(Get-RootScriptName)"
	$minParams = Get-MinimumRequiredParameterCount -CommandInfo (Get-Command $MyInvocation.MyCommand.Name)
	$cmd = @{}

	if(Get-BaseParamHelpFull) { $cmd.HelpFull = $true }
	if((Get-BaseParamHelpDetail) -Or ($PSBoundParameters.Count -lt $minParams)) { $cmd.HelpDetail = $true }
	if(Get-BaseParamHelpSynopsis) { $cmd.HelpSynopsis = $true }
	
	if($cmd.Count -gt 1) { Write-DisplayHelp -Name "$(Get-RootScriptPath)" -HelpDetail }
	if($cmd.Count -eq 1) { Write-DisplayHelp -Name "$(Get-RootScriptPath)" @cmd }
}
Process
{
	$modRootDir = "D:\AppDataFactorio\mods"
	$jsonFile = "info.json"

	try
	{
		$isDebug = Assert-Debug
		
		function Get-ModFiles()
		{
			$fileList = @()
			$files = Get-ChildItem -Path $modRootDir -File | Where-Object {$_.FullName -Match ".zip$"}
			
			foreach($f in $files)
			{
				$fileList += $f.FullName
			}
			
			return $fileList
		}

		function Get-ModDirectories()
		{
			$directories = @()
			$dirs = Get-ChildItem -Path $modRootDir -Directory

			foreach($d in $dirs)
			{
				$directories += $d.FullName
			}
			
			return $directories
		}

		$items = @()
		$finalItems = @()
		$c = 0

		if($Extract)
		{
			$items = Get-ModFiles
			
			foreach($fullPath in $items) 
			{
				$c++
			
				$displayPath = ($fullPath | Split-Path -Leaf)

				$entry = "  {0:d2}" -f [int32]$c
				Write-Host $entry -NoNewLine -ForegroundColor DarkYellow
				$entry = "     $displayPath"
				Write-Host $entry -ForegroundColor Cyan
				$finalItems += $fullPath
			}

			$selected = Read-Host 'Mod ZIP'
			
			$ss = -1;
			if([int]::TryParse($selected, [ref] $ss) -and $ss -ge 0 -and $ss -le $c) {
				$zipFile = $finalItems[$ss - 1]
			}	

			$mn = ($zipFile | Split-Path -Leaf)
			$mn = $mn.Substring(0, $mn.Length - 4)
			
			if ($PSCmdlet.ShouldProcess($zipFile, 'Extract to $modRootDir\$mn.')) 
			{
				& $sevenZipExe x -y "$zipFile" "-o$modRootDir\$mn"
				Start-Sleep -Seconds 2
			}
			
			$topModDir = $modRootDir + "\" + $mn
			$mds = Get-ChildItem $topModDir -Directory
			
			
			$finalLocation =  $topModDir + "\" + $mds[0].Name
		}
		else
		{
			$items = Get-ModDirectories
			
			foreach($fullPath in $items) 
			{
				$mds = Get-ChildItem $fullPath -Directory
				
				if($null -ne $mds)
				{
					$jsonPath = $fullPath + "\" + $mds[0].Name + "\" + $jsonFile

					if(Test-Path -Path $jsonPath)
					{
						$c++
						$info = Get-Content $jsonPath | ConvertFrom-Json
					
						$displayPath = $info.name

						$entry = "  {0:d2}" -f [int32]$c
						Write-Host $entry -NoNewLine -ForegroundColor DarkYellow
						$entry = "     $displayPath"
						Write-Host $entry -ForegroundColor Cyan
						$finalItems += $fullPath + "\" + $mds[0].Name
					}
				}
			}

			$selected = Read-Host 'Directory'
			
			$ss = -1;
			if([int]::TryParse($selected, [ref] $ss) -and $ss -ge 0 -and $ss -le $c) {
				$finalLocation = $finalItems[$ss - 1]
			}	
		}

		if ($PSCmdlet.ShouldProcess($finalLocation, 'Set location.')) 
		{
			Set-Location $finalLocation
		}
	}
	catch [System.Exception]
	{
		Write-DisplayError $PSItem.ToString() -Exit
	}
}
End
{
	Write-DisplayHost "Done." -Style Done
}
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------