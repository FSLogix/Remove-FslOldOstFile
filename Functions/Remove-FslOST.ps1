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
    } #BEGIN
    PROCESS {
        foreach ($vhd in $VHDPath) {

            $mount = Mount-VHD $vhd -Passthru

            $driveLetter = $mount | Get-Disk | Get-Partition | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1

            $ost = Get-ChildItem -Path (Join-Path $driveLetter *.ost) -Recurse

            $latestOst = $ost | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

            $ost | Where-Object {$_.Name -ne $latestOst.Name} | Remove-Item

            Dismount-VHD $vhd

        }

    } #PROCESS
    END {
    } #END
}#function

Remove-FslOST -VHDPath "E:\JimM\Test.vhd"