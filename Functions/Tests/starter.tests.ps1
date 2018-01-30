$vhdNumber = 3
Stop-Service -Name ShellHWDetection
For ($i = 1; $i -le $vhdNumber; $i++) {
    $vhdPath = 'c:\jimm\Test' + "$i" + '.vhdx'
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
