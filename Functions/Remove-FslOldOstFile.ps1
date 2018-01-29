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


    } #BEGIN
    PROCESS {
        Get-FslVHD -Path $FolderPath

    } #PROCESS
    END {
    } #END
}#function