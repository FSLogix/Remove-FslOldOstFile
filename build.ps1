# --- Set the uri for the latest release
$URI = "https://api.github.com/repos/JimMoyle/YetAnotherWriteLog/releases/latest"

# --- Query the API to get the url of the zip
$response = Invoke-RestMethod -Method Get -Uri $URI
$zipUrl = $Response.zipball_url

# --- Download the file to the current location
$OutputPath = "$((Get-Location).Path)\$($Response.name.Replace(" ","_")).zip"
Invoke-RestMethod -Method Get -Uri $ZipUrl -OutFile $OutputPath

Expand-Archive -Path $OutputPath -DestinationPath $env:TEMP\zip\ -Force

$writeLog = Get-ChildItem $env:TEMP\zip\ -Recurse -Include write-log.ps1 | Get-Content

Remove-Item $OutputPath
Remove-Item $env:TEMP\zip -Force -Recurse