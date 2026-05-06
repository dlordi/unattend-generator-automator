# These scripts will run when the first user logs on after Windows has been installed.

# Set-WinHomeLocation -GeoId 94;

foreach ($file_path in @(
		"$env:USERPROFILE\Desktop\desktop.ini" # desktop: delete annoying and useless desktop.ini hidden files
		"$env:USERPROFILE\Desktop\Microsoft Edge.lnk" # desktop: delete shortcut to Edge
	)) {
	if (Test-Path $file_path) {
		Remove-Item -Force $file_path
	}
}
