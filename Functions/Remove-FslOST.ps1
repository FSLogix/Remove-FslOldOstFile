function Remove-FslOST {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true,
            Position = 0,
            Mandatory = $true)]
        [String[]]$VHDPath
    )
    BEGIN {
        Set-StrictMode -Version Latest
        Write-Log 'Starting Remove-FslOST helper function'
        $totalFilesDeleted = 0
    } #BEGIN
    PROCESS {
        foreach ($vhd in $VHDPath) {

            Write-Log "Processing $vhd"

            try {
                Write-Log "Mounting $vhd"
                $mount = Mount-VHD $vhd -Passthru -ErrorAction Stop
                Write-Log "Mounted $vhd"
            }
            catch {
                #Write-Error $Error[0]
                Write-Log -level Error "Failed to mount $vhd"
                Write-Log -level Error "Stopping processing $vhd"
                break
            }

            $driveLetter = $mount | Get-Disk | Get-Partition | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1

            Remove-FslMultiOst -Path (Join-Path $driveLetter ODFC)
        
            try {
                Write-Log "Dismounting $vhd"
                Dismount-VHD $vhd -ErrorAction Stop
                Write-Log "Dismounted $vhd"
            }
            catch {
                write-log -level Error "Failed to Dismount $vhd vhd will need to be manually dismounted"
            }
            #$totalFilesDeleted = $totalFilesDeleted + $ostDelNum

            
        }

    } #PROCESS
    END {
        #Write-Output $totalFilesDeleted
        #Write-log "Leaving Remove-FslOST helper function"
    } #END
}#function