# --- Set the uri for the latest release
$URI = "https://api.github.com/repos/JimMoyle/YetAnotherWriteLog/releases/latest"

# --- Query the API to get the url of the zip
$Response = Invoke-RestMethod -Method Get -Uri $URI
$ZipUrl = $Response.zipball_url

# --- Download the file to the current location
$OutputPath = "$((Get-Location).Path)\$($Response.name.Replace(" ","_")).zip"
Invoke-RestMethod -Method Get -Uri $ZipUrl -OutFile $OutputPath

Get-ChildItem $OutputPath