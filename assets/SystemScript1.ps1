# These scripts will run in the system context, before user accounts are created.

# Set-MpPreference -DisableRealtimeMonitoring $true;

foreach ($file_path in @(
		# "$env:PUBLIC" is the home directory of a generic, public user profile
		"$env:PUBLIC\Desktop\desktop.ini", # desktop: delete annoying and useless desktop.ini hidden files
		"$env:PUBLIC\Desktop\Microsoft Edge.lnk" # desktop: delete shortcut to Edge
	)) {
	if (Test-Path $file_path) {
		Remove-Item -Force $file_path
	}
}
