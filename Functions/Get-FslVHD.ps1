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
        Write-Verbose 'Starting Get-FslVHD helper function'
        Write-Log 'Starting Get-FslVHD  helper function'
        try {
            $vhdDetail = Get-ChildItem -Path (Join-Path $path *.vhd*) -Recurse -ErrorAction Stop | Get-VHD -ErrorAction Stop
            Write-Log "Retrieved $($vhdDetail.count) vhds from specified path"
        }
        catch {
            Write-Error $Error[0]
            Write-Log 'Failed to get VHD details'
            Write-Log 'Stopping script'
            exit
        }

        try {
            $output = $vhdDetail | Select-Object -Property Path, VhdFormat, VhdType, FileSize, Size, Attached, @{n = 'FreeSpace'; e = {[math]::round((($_.Size - $_.FileSize) / [math]::pow( 1024, 3 )), 2)}}
            Write-Log 'Formated VHD details Correctly'
        }
        catch {
            Write-Error $Error[0]
            Write-Log  'Failed to format VHD details'
            Write-Log 'Stopping script'
            exit
        }
        Write-Output $output
        Write-Verbose 'Stopping Get-FslVHD helper function'
        Write-Log 'Stopping Get-FslVHD  helper function'
    } #PROCESS
    END {
    } #END
}#function

Get-FslVHD -Path E:\JimM