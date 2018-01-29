function Get-FslVHD {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true)]
        [String]$Path
    )
    BEGIN {
        Set-StrictMode -Version Latest
    } #BEGIN
    PROCESS {

        $vhdDetail = Get-ChildItem -Path (Join-Path $path *.vhd*) -Recurse | Get-VHD

        $output = $vhdDetail | Select-Object -Property Path, VhdFormat, VhdType, FileSize, Size, Attached, @{n = 'FreeSpace(GB)'; e = {[math]::round((($_.Size - $_.FileSize) / [math]::pow( 1024, 3 )),2)}}

        Write-Output $output

    } #PROCESS
    END {
    } #END
}#function

Get-FslVHD -Path E:\JimM