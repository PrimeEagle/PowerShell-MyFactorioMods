param([Alias("X")] [Parameter()]	[switch] $Extract)
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------


#. ($PSScriptRoot + "\mccmn.ps1");

$helpSummary = "Change the directory to a Factorio mod directory."
$helpUsage = " [-h]"
$helpExample = "cdmod"
$modRootDir = "D:\AppDataFactorio\mods"
$jsonFile = "info.json"
$7zip = "C:\Program Files\7-Zip\7z.exe"
#Show-Help $helpSummary $helpUsage $helpExample

#Write-Log "Execute: cdmod.ps1 $args"
# -----------------------------------------------------------------------------

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
	
	& $7zip x -y "$zipFile" "-o$modRootDir\$mn" #| Out-Null
	Start-Sleep -Seconds 2
	
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

Set-Location $finalLocation
# -----------------------------------------------------------------------------