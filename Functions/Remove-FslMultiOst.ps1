function Remove-FslMultiOst {
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String]$Path
    )

    BEGIN {
        Set-StrictMode -Version Latest
    } # Begin
    PROCESS {
        Write-Log  "Getting ost files from vhd(x)"
        $ost = Get-ChildItem -Path (Join-Path $Path *.ost) -Recurse
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
    } #Process
    END {} #End
}  #function Remove-FslMultiOst