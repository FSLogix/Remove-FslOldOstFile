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
        [int]$Number
    )
    BEGIN {
        Set-StrictMode -Version Latest

        #Get-FslVHD

    } #BEGIN
    PROCESS {
        Get-FslVHD -Path $FolderPath

    } #PROCESS
    END {
    } #END
}#function