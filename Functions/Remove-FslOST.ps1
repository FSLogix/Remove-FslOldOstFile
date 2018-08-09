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
           
            if (($null -eq $DriveLetter) -or ($driveLetter -like "*\\?\Volume{*")) {
                Write-Verbose "Did not receive valid driveletter: $Driveletter. Assigning guid."
                
                $guid_ID = ([guid]::NewGuid()).Guid
    
                $Partitions = get-partition -DiskNumber $mount.Number | Where-Object {$_.type -eq 'Basic'}
                $PartFolder = join-path "C:\programdata\fslogix\FslGuid" $guid_ID
                
                if (-not(test-path -path $PartFolder)) {
                    New-Item -ItemType Directory -Path $PartFolder | Out-Null 
                }else{
                    remove-item $PartFolder -Force
                }
                Add-PartitionAccessPath -InputObject $Partitions -AccessPath $PartFolder -ErrorAction Stop | Out-Null
                $DriveLetter = $PartFolder
                
            }

            if ($DriveLetter.Length -eq 3) {
                Write-Log "VHD Mounted on Path [$DriveLetter]"
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
