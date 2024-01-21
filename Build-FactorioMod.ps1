<#
	.SYNOPSIS
	Build Factorio mod package.
	
	.DESCRIPTION
	Build Factorio mod package.

	.PARAMETER Modular
	Modular build (build modules along with mod).
	
	.PARAMETER IncludeLibrary
	Include library functions in build.
	
	.PARAMETER RemoveLibrary
	Remove library functions from build.	
	
	.INPUTS
	None.

	.OUTPUTS
	None.

	.EXAMPLE
	PS> .\Build-FactorioMod.ps1 -IncludeLibrary
#>
using module Varan.PowerShell.Validation
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Requires -Version 5.0
#Requires -Modules Varan.PowerShell.Validation
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param (	[Parameter(Mandatory = $false)][Alias("M")]	[switch] $Modular,
		[Parameter(ParameterSetName = "IncludeLibrary", Mandatory = $false)][Alias("IL")]	[switch] $IncludeLibrary,
		[Parameter(ParameterSetName = "RemoveLibrary", Mandatory = $false)][Alias("RL")]	[switch] $RemoveLibrary
	  )
DynamicParam { Build-BaseParameters }

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
	try
	{
		$isDebug = Assert-Debug
		
		$base = "D:\AppDataFactorio\mods"
		$peLib = "PE-Lib"
		$jsonFile = "info.json"
		$modulesDir = "modules"
		$chainsDir = "chains"
		$libDir = "lib"
		$graphicsDir = "graphics"

		class ModVersionInfo
		{
			[string] $OldVersion
			[string] $NewVersion
		}

		class ModPathInfo
		{
			[string] $TopPath
			[string] $SubPath
		}

		function Get-ModName(	[Parameter(Mandatory = $true)]  [string] $Path,
								[Parameter()]					[switch] $Module,
								[Parameter()]					[switch] $Chain)
		{
			$result = ""

			$jsonPath = $Path + "\" + $jsonFile
			
			if(Test-Path -Path $jsonPath)
			{
				$info = Get-Content $jsonPath | ConvertFrom-Json
				return $info.name
			}
			else
			{
				$msg = ""
				if($Module) { $msg = "  " }
				elseif($Chain) { $msg = "    " }
				else { $msg = "" }
				
				$msg = $msg + "no info.json in '$($Path | Split-Path -Leaf)' "
				Write-Host $msg -NoNewLine
			}
			
			return $result
		}

		function Get-ModVersions(	[Parameter(Mandatory = $true)]  [string] $Path,
									[Parameter()]					[switch] $Module,
									[Parameter()]					[switch] $Chain)
		{
			$result = New-Object ModVersionInfo

			$jsonPath = $Path + "\" + $jsonFile

			if(Test-Path $jsonPath)
			{
				$info = Get-Content $jsonPath | ConvertFrom-Json
				$result.NewVersion = $info.version
				$result.OldVersion = $Path.Substring($Path.LastIndexOf("_") + 1)
			}
			else
			{
				$msg = ""
				if($Module) { $msg = "  " }
				elseif($Chain) { $msg = "    " }
				else { $msg = "" }
				
				$msg = $msg + "no info.json in '$($Path | Split-Path -Leaf)' "
				Write-Host $msg -NoNewLine
			}
			return $result
		}

		function Update-ModVersion( [Parameter(Mandatory = $true)]  [string] $Path, 
									[Parameter(Mandatory = $true)]  [string] $ModName, 
									[Parameter(Mandatory = $true)]  [ModVersionInfo]$VersionInfo)
		{
			$result = ""

			$oldName = ($Path | Split-Path -Leaf)
			if($oldName.IndexOf("_") -ge 0)
			{
				$oldName = $oldName.Substring(0, $oldName.LastIndexOf("_"))
			}
			
			if(($oldName -ne $ModName) -Or ($VersionInfo.OldVersion -ne $VersionInfo.NewVersion))
			{
				$newName = ($ModName + "_" + $VersionInfo.NewVersion)
				$leaf = ($Path | Split-Path -Leaf)
				$dir = $Path.Substring(0, $Path.Length - $leaf.Length) + $newName

				Rename-Item -Path $Path $newName 
				
				$result = $dir
			}
			else
			{
				$result = $Path
			} 
			
			return $result
		}

		function Compress-Mod(	[Parameter(Mandatory = $true)]  [string] $ModName, 
								[Parameter(Mandatory = $true)]  [ModVersionInfo]$VersionInfo,
								[Parameter(Mandatory = $true)]  [string]$Path)
		{
			$oldZipName = $ModName + "_" + $VersionInfo.OldVersion + ".zip"
			$newZipName = $ModName + "_" + $VersionInfo.NewVersion + ".zip"

			$oldZipPath = $base + "\" + $oldZipName
			$newZipPath = $base + "\" + $newZipName

			if(Test-Path $oldZipPath)
			{
				Remove-Item -Path $oldZipPath -Force
			}
			
			& $sevenZipExe a -r "$newZipPath" "$Path*.*" "-xr!todo*.txt" "-xr!*.vsdx" "-xr!*.bat" "-xr!*.xlsx"   | Out-Null
		}

		$modPath = Get-Location
		Set-Location "D:\"

		$modName = Get-ModName -Path $modPath
		if($modName.Length -eq 0)
		{
			Set-Location $modPath
			Write-Host ", make sure you're in a mod directory"
			Write-Host "terminating"
			exit
		}

		if($IncludeLibrary)
		{
			Write-Host "copying library..." -NoNewLine
			$mpaths = Get-ChildItem $base -Directory
			
			foreach($mp in $mpaths)
			{
				if($mp.Name.StartsWith($peLib))
				{
					$peTopPath = $mp.FullName
					break
				}
			}
			
			$peChild = Get-ChildItem $peTopPath -Directory
			$pePath = $peChild[0].FullName

			if(-Not (Test-Path "$modPath\$libDir"))
			{
				New-Item -Path "$modPath\" -Name "$libDir" -ItemType "Directory" | Out-Null
			}
			
			if(-Not (Test-Path "$modPath\$graphicsDir\$libDir"))
			{
				New-Item -Path "$modPath\$graphicsDir\" -Name "$libDir" -ItemType "Directory" | Out-Null
			}

			Copy-Item -Path "$pePath\*" -Destination "$modPath\$libDir" -Include *.lua -Recurse -Force
			Copy-Item -Path "$pePath\$graphicsDir\$libDir\*" -Destination "$modPath\$graphicsDir\$libDir" -Recurse -Force
			Write-Host "done"
		}

		if($RemoveLibrary)
		{
			Write-Host "removing library..." -NoNewLine
			if(Test-Path "$modPath\$libDir")
			{
				Remove-Item -Recurse -Force "$modPath\$libDir"
			}
			
			if(Test-Path "$modPath\$graphicsDir\$libDir")
			{
				Remove-Item -Recurse -Force "$modPath\$graphicsDir\$libDir"
			}
			Write-Host "done"
		}
			

		Write-Host "building mod $modName"
		Write-Host "compiling mod $modName..." -NoNewLine

		$modVersions = Get-ModVersions -Path $modPath
		if($modVersions.NewVersion.Length -eq 0)
		{
			Set-Location $modPath
			Write-Host "terminating"
			exit
		}

		$modPath = Update-ModVersion -Path $modPath -ModName $modName -VersionInfo $modVersions
		$mpLeaf = ($modPath | Split-Path -Leaf)
		$topPath = $modPath.Substring(0, $modPath.Length - $mpLeaf.Length)
		$newTopPath = $topPath.Replace($modVersions.OldVersion, $modVersions.NewVersion)
				
		if($topPath -ne $newTopPath)
		{
			Rename-Item -Path $topPath ($newTopPath | Split-Path -Leaf)
		}
		$modPath = $newTopPath + $mpLeaf

		Compress-Mod -ModName $modName -VersionInfo $modVersions -Path $newTopPath
		Set-Location $modPath
		Write-Host "done"

		if($Modular)
		{
			Write-Host "modular compilation starting."
			
			$moduleBase = $modPath + "\" + $modulesDir
			if(Test-Path $moduleBase)
			{
				$moduleDirList = Get-ChildItem -Path $moduleBase -Directory
				
				if($moduleDirList.Length -eq 0)
				{
					Write-Host "no modules found"
				}
				else
				{
					foreach($md in $moduleDirList)
					{	
						$mn = Get-ModName -Path $md.FullName -Module
						if($mn.Length -eq 0)
						{
							Set-Location $modPath
							Write-Host "  skipping"
							continue
						}
						Write-Host "  compiling module $mn..." -NoNewLine
						$mv = Get-ModVersions -Path $md.FullName -Module
						if($mv.NewVersion.Length -eq 0)
						{
							Set-Location $modPath
							Write-Host "  skipping"
							continue
						}
						$mp = Update-ModVersion -Path $md.FullName -ModName $mn -VersionInfo $mv
						Compress-Mod -ModName $mn -VersionInfo $mv -Path $mp
						Write-Host "  done."
						
						$chainBase = $md.FullName + "\" + $chainsDir

						if(Test-Path $chainBase)
						{
							$chainDirList = Get-ChildItem -Path $chainBase -Directory
							
							if($chainDirList.Length -eq 0)
							{
								Write-Host "no chains found"
							}
							else
							{
								foreach($cd in $chainDirList)
								{
									$cn = Get-ModName -Path $cd.FullName -Chain
									
									if($cn.Length -eq 0)
									{
										Set-Location $modPath
										Write-Host "  skipping"
										continue
									}
									
									Write-Host "    compiling chain $cn..." -NoNewLine
									$cv = Get-ModVersions -Path $cd.FullName -Chain
									if($cv.NewVersion.Length -eq 0)
									{
										Set-Location $modPath
										Write-Host "  skipping"
										continue
									}
									
									$cp = Update-ModVersion -Path $cd.FullName -ModName $cn -VersionInfo $cv
									Compress-Mod -ModName $cn -VersionInfo $cv -Path $cp
									Write-Host "    done."
								}
							}
						}
					}
				}
			}
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