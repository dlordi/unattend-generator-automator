<#
```bat
powershell -ExecutionPolicy Bypass -File .\Conv-AutounattendXmlToIni.ps1 <template_name>
```

```ps1
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass
.\Conv-AutounattendXmlToIni.ps1 <template_name>
```
#>

param (
  [Parameter()][ValidateNotNullOrEmpty()][string]$template_name = $(throw 'template_name is mandatory, please provide a value.')
)

$oldEAP = $ErrorActionPreference
$oldPP = $ProgressPreference

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

try {
  Add-Type -AssemblyName System.Web

  $utf8 = New-Object System.Text.UTF8Encoding $false

  $url = ''
  foreach ($line in Get-Content "$PSScriptRoot\$template_name.xml") {
    if ($line -match '^\s*<!--https://schneegans.de/windows/unattend-generator/') {
      $url = ($line -split '--')[1]
      break
    }
  }
  if (-not $url) { throw "cannot find link in $template_name.xml" }

  $assets_dir = "$PSScriptRoot\assets"
  if (-not (Test-Path -PathType container $assets_dir)) {
    New-Item -ItemType Directory -Force -Path $assets_dir
  }

  $conf_ini = @()
  $qs = [System.Web.HttpUtility]::ParseQueryString(([System.Uri]$url).Query)
  foreach ($k in $qs.AllKeys) {
    if (-not($k -and $k.Trim())) { continue }

    $v = $qs[$k]
    if ($k -match '^(DefaultUserScript|FirstLogonScript|SystemScript|UserOnceScript)') {
      if ($k -match 'Type') {
        continue
      }
      $ext = $qs["$($k.Substring(0, $k.Length - 1))Type$($k.Substring($k.Length - 1))"].ToLower()

      $asset_file_name = "$k.$ext"
      [System.IO.File]::WriteAllLines("$assets_dir\$asset_file_name", $v, $utf8)
      $v = "<<$asset_file_name"
    } elseif ($k -eq 'DiskAssertionScript') {
      $asset_file_name = "$k.vbs"
      [System.IO.File]::WriteAllLines("$assets_dir\$asset_file_name", $v, $utf8)
      $v = "<<$asset_file_name"
    }
    $conf_ini += "$k=$v"
  }
  [System.IO.File]::WriteAllLines("$PSScriptRoot\$template_name.ini", $conf_ini, $utf8)
} finally {
  $ErrorActionPreference = $oldEAP
  $ProgressPreference = $oldPP
}
