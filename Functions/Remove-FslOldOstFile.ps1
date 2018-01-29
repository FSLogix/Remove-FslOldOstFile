function Remove-FslOldOstFile {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true)]
        [String]$FolderPath,

        [Parameter(
            Position = 1,
            Mandatory = $true,
            HelpMessage = 'The script will process VHDs with less free space than specified here')]
        [int]$FreeSpace,

        [Parameter(
            Position = 2)]
        [String]$LogPath = 'C:\Users\Jim\AppData\Local\Temp\FSlogixRemoveOST.log'
    )
    BEGIN {
        Set-StrictMode -Version Latest

        #Region helper functions
            #Write-Log
            #Get-FslVHD
            #Remove-FslOST
        #endregion

        Write-Log -StartNew
        $PSDefaultParameterValues = @{"Write-Log:Path" = "$LogPath"}
    } #BEGIN
    PROCESS {

        Write-Verbose 'Starting Remove-FslOldOstFile'
        Write-Log 'Starting Remove-FslOldOstFile'
        $vhdList = Get-FslVHD -Path $FolderPath -Verbose:$VerbosePreference
        $vhdToProcess = $vhdList | Where-Object {$_.Attached -eq $false -and $_.FreeSpace -lt $FreeSpace}
        $vhdToProcess | Remove-FslOST -Verbose:$VerbosePreference
        Write-Verbose 'Finished Remove-FslOldOstFile'
        Write-Log 'Finished Remove-FslOldOstFile'
    } #PROCESS
    END {
        Write-Log 'Script Finished'
    } #END
}#function