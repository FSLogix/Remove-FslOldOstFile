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

            #If the VHD does not have a drive letter assigned, then the available drive
            #will be \\?\Volume{*}, which will result in the script unable to function.
            $driveLetter = $mount | Get-Disk | Get-Partition | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1
            if ($driveLetter -like "*\\?\Volume{*") {
                        
                Write-Log "$driveLetter is not a valid drive letter"
                $driveLetter = $mount | get-disk | Get-Partition | Add-PartitionAccessPath -AssignDriveLetter | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1
                        
                if ($null -eq $driveLetter) {
                    #Refresh mount
                            
                    try {
                        #For some reason, If the first the driveLetter obtained was \\?\Volume
                        #Then the new drive letter assigned will be null unless updated.
                        Write-Log "DriverLetter is null, Re-Mounting"
                        Dismount-VHD $vhd -Passthru -ErrorAction Stop
                    }
                    catch {
                        Write-Error $Error[0]
                        Write-Log -Level Error "Failed to Dismount $vhd vhd will need to be manually dismounted"
                    }

                    try {
                        Mount-VHD $vhd -Passthru -ErrorAction Stop
                        $driveLetter = $mount | get-disk | Get-Partition | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1
                        Write-Log "Remounted $vhd"
                    }
                    catch {
                        Write-Log -level Error "Failed to Re-Mount $vhd"
                        Write-Log -level Error "Stopping processing $vhd"
                        break
                    }
                            
                }
                Write-Log "Assigning drive letter: $driveLetter"
            }
            else {
                Write-Log "VHD mounted on drive letter [$DriveLetter]"
            }
            Write-Log "Getting ost files from $vhd"



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