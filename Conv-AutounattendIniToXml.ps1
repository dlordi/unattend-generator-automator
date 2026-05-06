<#
```bat
powershell -ExecutionPolicy Bypass -File .\Conv-AutounattendIniToXml.ps1 <template_name>
```

```ps1
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass
.\Conv-AutounattendIniToXml.ps1 <template_name>
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

  $ToTitleCase = { param($s) "$($s.Substring(0, 1).ToUpper())$($s.Substring(1))" }

  $qs = [ordered]@{}
  foreach ($line in Get-Content "$PSScriptRoot\$template_name.ini") {
    $line = $line.Replace('(^\s+|\s+$)', '')
    $k, $v = $line -split '='
    if ($v -match '^<<(.*)$') {
      $asset_file_name = $Matches[1]
      if ($k -match '^(DefaultUserScript|FirstLogonScript|SystemScript|UserOnceScript)') {
        # add extra parameter to set the script type by its extension
        $qs["$($k.Substring(0, $k.Length - 1))Type$($k.Substring($k.Length - 1))"] = &$ToTitleCase ($asset_file_name -split '\.')[-1]
      }
      $v = Get-Content "$PSScriptRoot\assets\$asset_file_name" -Raw
    }
    $qs[$k] = $v
  }

  $url = 'https://schneegans.de/windows/unattend-generator/view/?'
  foreach ($k in $qs.GetEnumerator()) {
    $url = "$url$($k.Key)=$([System.Web.HttpUtility]::UrlEncode($k.Value))&"
  }
  $url = $url.Substring(0, $url.Length - 1) # remove trailing &
  # argument "-UseBasicParsing" added after system update (see https://www.bleepingcomputer.com/news/security/microsoft-windows-powershell-now-warns-when-running-invoke-webrequest-scripts/)
  [System.IO.File]::WriteAllText("$template_name.xml", (Invoke-WebRequest -UseBasicParsing $url).Content, $utf8)
} finally {
  $ErrorActionPreference = $oldEAP
  $ProgressPreference = $oldPP
}
