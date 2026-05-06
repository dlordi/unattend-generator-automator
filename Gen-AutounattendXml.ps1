<#
```bat
powershell -ExecutionPolicy Bypass -File .\Gen-AutounattendXml.ps1 <template_name> <image_name>
```

```ps1
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass
.\Gen-AutounattendXml.ps1 <template_name> <image_name>
```
#>

param (
  [Parameter(Mandatory = $true)][string]$template_name,
  [Parameter(Mandatory = $true)][string]$image_name
)

function New-SSHKeys {
  param([string] $path)

  if (Test-Path $path) { Remove-Item -Force $path }
  if (Test-Path "$path.pub") { Remove-Item -Force "$path.pub" }

  ssh-keygen -f "$path" -N '""'

  if (-not (Test-Path $path) -or -not (Test-Path "$path.pub")) { throw 'ERROR: cannot create SSH keys' }
}

function Convert-ToHex {
  param([string]$inputString)

  return ( -Join (($inputString | Format-Hex).ToString().Split([Environment]::NewLine) | ForEach-Object { $_[11..58] })) -Replace ' ', ''
}

# https://stackoverflow.com/questions/72236557/how-do-i-read-a-env-file-from-a-ps1-script
Get-Content "$PSScriptRoot\.env" | ForEach-Object {
  $line = $_.Trim()
  if ($line -eq '' -or $line.StartsWith('#')) { return } # skip commented and empty lines

  $parts = $line.Split('=', 2) # split on '=' only once
  if ($parts.Count -lt 2) { return } # skip invalid lines

  $name = $parts[0].Trim()
  $value = $parts[1].Trim()
  Set-Content env:\$name $value
}

# if "$fake_product_key" is not present in the template, no replacement will occur (this allows to use UEFI/BIOS product key)
$fake_product_key = 'VK7JG-NPHTM-C97JM-9MPGT-3V66T'
$wifi_name_hex = Convert-ToHex '__THE_WIFI_NAME__'
$real_hex = Convert-ToHex "$env:THE_WIFI_NAME"
$ssh_key_path = "$PSScriptRoot\build\id_ed25519"

New-SSHKeys -Path $ssh_key_path

# https://stackoverflow.com/questions/17144355/how-can-i-replace-every-occurrence-of-a-string-in-a-file-with-powershell
(Get-Content "$PSScriptRoot\$template_name.xml") | ForEach-Object {
  # only replace placeholder values which are not in the URL
  $_. `
    Replace("$fake_product_key", $env:PRODUCT_KEY). `
    Replace('"__THE_WIFI_NAME__"', "`"$env:THE_WIFI_NAME`""). `
    Replace('&lt;name&gt;__THE_WIFI_NAME__&lt;/name&gt;', "&lt;name&gt;$env:THE_WIFI_NAME&lt;/name&gt;"). `
    Replace("&lt;hex&gt;$wifi_name_hex&lt;/hex&gt;", "&lt;hex&gt;$real_hex&lt;/hex&gt;"). `
    Replace('&lt;keyMaterial&gt;__THE_WIFI_PASSWORD__&lt;/keyMaterial&gt;', "&lt;keyMaterial&gt;$env:THE_WIFI_PASSWORD&lt;/keyMaterial&gt;"). `
    Replace('<Name>__THE_USER_NAME__</Name>', "<Name>$env:THE_USER_NAME</Name>"). `
    Replace('<Username>__THE_USER_NAME__</Username>', "<Username>$env:THE_USER_NAME</Username>"). `
    Replace('<Value>__THE_USER_PASSWORD__</Value>', "<Value>$env:THE_USER_PASSWORD</Value>"). `
    Replace('__THE_USER_PRIVATE_SSH_KEY__', [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($ssh_key_path))). `
    Replace('__THE_USER_PUBLIC_SSH_KEY__', [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$ssh_key_path.pub"))). `
    Replace('^"__THE_IMAGE_NAME__^"', "^`"$image_name^`"")
} | Set-Content "$PSScriptRoot\autounattend.xml"

if (Test-Path $ssh_key_path) { Remove-Item -Force $ssh_key_path }
if (Test-Path "$ssh_key_path.pub") { Remove-Item -Force "$ssh_key_path.pub" }
