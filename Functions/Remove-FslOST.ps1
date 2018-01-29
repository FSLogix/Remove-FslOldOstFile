function Remove-FslOST {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true)]
        [String[]]$VHDPath
    )
    BEGIN {
        Set-StrictMode -Version Latest
        Write-Log 'Starting Remove-FslOST helper function'
    } #BEGIN
    PROCESS {
        foreach ($vhd in $VHDPath) {

            Write-Log "Processing $($vhd.name)"

            try {
                Write-Log "Mounting $($vhd.name)"
                $mount = Mount-VHD $vhd -Passthru -ErrorAction Stop
                Write-Log "Mounted $($vhd.name)"
            }
            catch {
                #Write-Error $Error[0]
                Write-Log -level Error "Failed to mount $($vhd.name)"
                Write-Log -level Error "Stopping processing $($vhd.name)"
                break
            }

            $driveLetter = $mount | Get-Disk | Get-Partition | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1

            Write-Log  "Getting ost files from vhd(x)"
            $ost = Get-ChildItem -Path (Join-Path $driveLetter *.ost) -Recurse
            if ($ost.count -gt 0) {
                Write-Log  "Found $($ost.count) ost files"
            }
            else {
                Write-log -level Warn "Did not find any ost files in $($vhd.name)"
            }

            if ($ost.count -gt 1) {
                $ostDelNum = $ost.count - 1
                Write-Log "Deleting $ostDelNum ost files"
                try {
                    $latestOst = $ost | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
                    $ost | Where-Object {$_.Name -ne $latestOst.Name} | Remove-Item -Force -ErrorAction Stop
                }
                catch {
                    write-log -level Error "Failed to delete ost files in $($vhd.name)"
                }
            }
            try {
                Write-Log "Dismounting $($vhd.name)"
                Dismount-VHD $vhd -ErrorAction Stop
                Write-Log "Dismounted $($vhd.name)"
            }
            catch {
                write-log -level Error "Failed to Dismount $($vhd.name) vhd will need to be manually dismounted"
            }
        }

    } #PROCESS
    END {
        Write-log "Leaving Remove-FslOST helper function"
    } #END
}#function