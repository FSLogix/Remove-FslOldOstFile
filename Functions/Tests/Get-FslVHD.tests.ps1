$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$here = Split-Path $here
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe Get-FslVHD {

    BeforeAll {
        if (-not (Test-Path C:\JimM\Temp\1.vhdx)) {
            #Remove-Item C:\JimM\Temp\*.vhdx -Force -ErrorAction SilentlyContinue
            $vhdNumber = 10
            Stop-Service -Name ShellHWDetection
            For ($i = 1; $i -le $vhdNumber; $i++) {
                $folderpath = 'C:\JimM\Temp\' + "$i"
                New-Item $folderpath -ItemType directory
                $vhdPath = "$folderpath" + '\' + "$i" + '.vhdx'
                New-VHD -Path $vhdPath -SizeBytes 1073741824
                $m = Mount-VHD $vhdPath -Passthru
                $m | Initialize-Disk -PassThru -Confirm:$false |
                    New-Partition -AssignDriveLetter -UseMaximumSize |
                    Format-Volume -FileSystem NTFS -Confirm:$false -Force
                $driveLetter = $m | Get-Disk | Get-Partition | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1

                $numOst = Get-Random -Maximum 10 -Minimum 0

                For ($j = 1; $j -le $numOst; $j++) {
                    $fileName = "$j" + '.ost'
                    New-item (Join-Path $driveLetter $fileName)
                }

                Dismount-VHD -Path $vhdPath
            }

            Start-Service -Name ShellHWDetection
        }
        . ..\write-Log.ps1
    }

    Mock Write-Log {return $null}

    It 'Does Not Throw' {
        { Get-FslVHD -Path C:\JimM\Temp\ } | Should Not throw
    }
    It 'Finds 3 vhds' {
        $result = Get-FslVHD -Path C:\JimM\Temp
        $result.path.count | Should Be 3
    }
    It 'Has seven props' {
        $result = Get-FslVHD -Path C:\JimM\Temp
        $result.count | Should Be 7
    }
}