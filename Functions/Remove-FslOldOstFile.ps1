function Remove-FslOldOstFile {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true)]
        [String]$FolderPath,

        [Parameter(
            Position = 2)]
        [String]$LogPath = (Join-path $Env:Temp FSlogixRemoveOST.log)
    )
    BEGIN {
        Set-StrictMode -Version Latest

        #Region helper functions
            #Write-Log
            #Get-FslVHD
            #Remove-FslOST
            #Remove-FslMultiOST
        #endregion

        Write-Log -StartNew -Path $LogPath
        if ($PSVersionTable.PSVersion -lt [version]"5.0.0.0") {
            Write-Log -Level Error 'Powershell must be version 5 or above for this script to run'
            Write-Error 'Powershell must be version 5 or above for this script to run'
            exit
        }
        if ((Get-Module -ListAvailable).Name -notcontains 'Hyper-V') {
            Write-Log -Level Error 'Hyper-V module must be available'
            Write-Error 'Hyper-V module must be available'
            exit
        }
        $PSDefaultParameterValues = @{"Write-Log:Path" = "$LogPath"}
    } #BEGIN
    PROCESS {

        Write-Verbose 'Starting Remove-FslOldOstFile'
        Write-Log 'Starting Remove-FslOldOstFile'
        $vhdList = Get-FslVHD -Path $FolderPath -Verbose:$VerbosePreference
        $vhdToProcess = $vhdList | Where-Object { $_.Attached -eq $false }
        $result = $vhdToProcess.path | Remove-FslOST -Verbose:$VerbosePreference
        $count = ($vhdToProcess | Measure-Object).Count
        Write-Log "Deleted $result ost files from $count VHD(X)s"
        Write-Verbose 'Finished Remove-FslOldOstFile'
        Write-Log 'Finished Remove-FslOldOstFile'
    } #PROCESS
    END {
        Write-Log 'Script Completed'
    } #END
}#function