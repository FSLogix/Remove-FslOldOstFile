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

            Write-Log  "Getting ost files from vhd(x)"
            $ost = Get-ChildItem -Path (Join-Path $driveLetter *.ost) -Recurse
            if ($null -eq $ost) {
                Write-log -level Warn "Did not find any ost files in $vhd"
                $ostDelNum = 0
            }
            else {

                if ($count -gt 1) {

                    $mailboxes = $ost.BaseName.trimend('(', ')', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0') | Group-Object | Select-Object -ExpandProperty Name

                    foreach ($mailbox in $mailboxes) {
                        $mailboxOst = $ost | Where-Object {$_.BaseName.StartsWith($mailbox)}

                        #So this is weird if only one file is there it doesn't have a count property! Probably better to use measure-object
                        try {
                            $mailboxOst.count | Out-Null
                            $count = $mailboxOst.count
                        }
                        catch {
                            $count = 1
                        }
                        Write-Log  "Found $count ost files for $mailbox"

                        if ($count -gt 1) {

                            $ostDelNum = $count - 1
                            Write-Log "Deleting $ostDelNum ost files"
                            try {
                                $latestOst = $mailboxOst | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
                                $mailboxOst | Where-Object {$_.Name -ne $latestOst.Name} | Remove-Item -Force -ErrorAction Stop
                            }
                            catch {
                                write-log -level Error "Failed to delete ost files in $vhd for $mailbox"
                            }

                            Remove-Variable -Name ost -ErrorAction SilentlyContinue
                        }
                        else {
                            Write-Log "Only One ost file found for $mailbox. No action taken"
                            $ostDelNum = 0
                        }

                    }
                }
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
        }

    } #PROCESS
    END {
        #Write-Output $totalFilesDeleted
        #Write-log "Leaving Remove-FslOST helper function"
    } #END
}#function