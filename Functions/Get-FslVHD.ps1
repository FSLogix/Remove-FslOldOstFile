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
            $vhdDetail = Get-ChildItem -Path (Join-Path $path *.vhd*) -Recurse -ErrorAction Stop | Get-VHD -ErrorAction SilentlyContinue
        }
        catch {
            Write-Error $Error[0]
            Write-Log 'Failed to get VHD details'
            Write-Log 'Stopping script'
            exit
        }
        
        if($null -eq $vhdDetail) {
            Write-Log "Retrieved 0 VHDs from specified Path."
            Exit
        }
        
        $count = ($vhdDetail | Measure-Object).Count
        Write-Log "Retrieved $count vhds from specified path"


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
