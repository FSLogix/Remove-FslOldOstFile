function Remove-FslOldOstFile {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true)]
        [String]$FolderPath,
        [Parameter(
            Position = 1,
            Mandatory = $true)]
        [int]$FreeSpace,
        [Parameter(
            Position = 2)]
        [String]$LogPath = $env:TEMP
    )
    BEGIN {
        Set-StrictMode -Version Latest

        #Write-Log
        #Get-FslVHD
        #Remove-FslOST

    } #BEGIN
    PROCESS {

        $vhdList = Get-FslVHD -Path $FolderPath
        $vhdToProcess = $vhdList | Where-Object {$_.Attached -eq $false -and $_.FreeSpace -lt $FreeSpace}
        $vhdToProcess | Remove-FslOST

    } #PROCESS
    END {
    } #END
}#function