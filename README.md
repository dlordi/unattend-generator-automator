# Usage example

- with PowerShell:

```ps1
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\Conv-AutounattendIniToXml.ps1 "default" # requires internet connection
.\Gen-AutounattendXml.ps1 "default" "Windows 10 Pro"
# copy generated "autounattend.xml" on media device
```
