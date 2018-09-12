function Remove-FslOldOstFile {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true)]
        [String]$FolderPath,

        [Parameter(
            Position = 1,
            Mandatory = $true,
            HelpMessage = 'The script will process VHDs with less free space than specified here')]
        [int]$FreeSpace,

        [Parameter(
            Position = 2)]
        [String]$LogPath = (Join-path $Env:Temp FSlogixRemoveOST.log)
    )
    BEGIN {
        Set-StrictMode -Version Latest

        #Region helper functions
            #Write-Log
function Write-Log {
    [CmdletBinding(DefaultParametersetName = "LOG")]
    Param (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'LOG')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false,
            Position = 1,
            ParameterSetName = 'LOG')]
        [ValidateSet("Error", "Warn", "Info")]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false,
            Position = 2)]
        [string]$Path = "$env:temp\PowershellScript.log",

        [Parameter(Mandatory = $false,
            Position = 3,
            ParameterSetName = 'STARTNEW')]
        [switch]$StartNew,

        [Parameter(Mandatory = $false,
            Position = 4,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'EXCEPTION')]
        [System.Management.Automation.ErrorRecord]$Exception

    )

    BEGIN {
        Set-StrictMode -version Latest
        $expandedParams = $null
        $PSBoundParameters.GetEnumerator() | ForEach-Object { $expandedParams += ' -' + $_.key + ' '; $expandedParams += $_.value }
        Write-Verbose "Starting: $($MyInvocation.MyCommand.Name)$expandedParams"
    }
    PROCESS {

        switch ($PSCmdlet.ParameterSetName) {
            EXCEPTION {
                Write-Log -Level Error -Message $Exception.Exception.Message -Path $Path
                break
            }
            STARTNEW {
                Write-Verbose -Message "Deleting log file $Path if it exists"
                Remove-Item $Path -Force -ErrorAction SilentlyContinue
                Write-Verbose -Message 'Deleted log file if it exists'
                Write-Log 'Starting Logfile' -Path $Path
                break
            }
            LOG {
                Write-Verbose 'Getting Date for our Log File'
                $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Verbose 'Date is $FormattedDate'

                switch ( $Level ) {
                    'Error' { $LevelText = 'ERROR:  '; break }
                    'Warn'  { $LevelText = 'WARNING:'; break }
                    'Info'  { $LevelText = 'INFO:   '; break }
                }

                $logmessage = "$FormattedDate $LevelText $Message"
                Write-Verbose $logmessage

                $logmessage | Add-Content -Path $Path
            }
        }

    }
    END {
        Write-Verbose "Finished: $($MyInvocation.Mycommand)"
    }
} # enable logging
            #Get-FslVHD
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
            #Remove-FslOST
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
            
            ## Usually this bug occurs when we are trying to mount a VHD, and the assigned Drive letter is already in use ##
            if ($null -eq $driveLetter) {
                try {
                    $disk = Get-Disk | Where-Object {$_.Location -eq $vhd}
                    $disk | set-disk -IsOffline $false
                }
                catch {
                    Write-Error $Error[0]
                }
                $driveLetter = $disk | Get-Partition | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1
            }
            
            ## If the VHD does not have a drive letter assigned, then the available drive ##
            ## will be \\?\Volume{*}, which will result in the script unable to function. ##
            if ($driveLetter -like "*\\?\Volume{*") {
                        
                Write-Log "$driveLetter is not a valid drive letter"
                $driveLetter = $mount | get-disk | Get-Partition | Add-PartitionAccessPath -AssignDriveLetter | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1
                        
                if ($null -eq $driveLetter) {
                    #Refresh mount
                            
                    try {
                        ## For some reason, If the first the driveLetter obtained was \\?\Volume ##
                        ## Then the new drive letter assigned will be null unless updated.       ##
                        Write-Log "DriverLetter is null, Re-Mounting"
                        Dismount-VHD $vhd -Passthru -ErrorAction Stop
                    }
                    catch {
                        Write-Error $Error[0]
                        Write-Log -Level Error "Failed to Dismount $vhd vhd will need to be manually dismounted"
                    }

                    try {
                        Mount-VHD $vhd -Passthru -ErrorAction Stop
                        $driveLetter = $mount | get-disk | Get-Partition | Select-Object -ExpandProperty AccessPaths | Select-Object -first 1
                        Write-Log "Remounted $vhd"
                    }
                    catch {
                        Write-Log -level Error "Failed to Re-Mount $vhd"
                        Write-Log -level Error "Stopping processing $vhd"
                        break
                    }
                            
                }
                Write-Log "Assigning drive letter: $driveLetter"
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
function Write-Log {
    [CmdletBinding(DefaultParametersetName = "LOG")]
    Param (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'LOG')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false,
            Position = 1,
            ParameterSetName = 'LOG')]
        [ValidateSet("Error", "Warn", "Info")]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false,
            Position = 2)]
        [string]$Path = "$env:temp\PowershellScript.log",

        [Parameter(Mandatory = $false,
            Position = 3,
            ParameterSetName = 'STARTNEW')]
        [switch]$StartNew,

        [Parameter(Mandatory = $false,
            Position = 4,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'EXCEPTION')]
        [System.Management.Automation.ErrorRecord]$Exception

    )

    BEGIN {
        Set-StrictMode -version Latest
        $expandedParams = $null
        $PSBoundParameters.GetEnumerator() | ForEach-Object { $expandedParams += ' -' + $_.key + ' '; $expandedParams += $_.value }
        Write-Verbose "Starting: $($MyInvocation.MyCommand.Name)$expandedParams"
    }
    PROCESS {

        switch ($PSCmdlet.ParameterSetName) {
            EXCEPTION {
                Write-Log -Level Error -Message $Exception.Exception.Message -Path $Path
                break
            }
            STARTNEW {
                Write-Verbose -Message "Deleting log file $Path if it exists"
                Remove-Item $Path -Force -ErrorAction SilentlyContinue
                Write-Verbose -Message 'Deleted log file if it exists'
                Write-Log 'Starting Logfile' -Path $Path
                break
            }
            LOG {
                Write-Verbose 'Getting Date for our Log File'
                $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Verbose 'Date is $FormattedDate'

                switch ( $Level ) {
                    'Error' { $LevelText = 'ERROR:  '; break }
                    'Warn'  { $LevelText = 'WARNING:'; break }
                    'Info'  { $LevelText = 'INFO:   '; break }
                }

                $logmessage = "$FormattedDate $LevelText $Message"
                Write-Verbose $logmessage

                $logmessage | Add-Content -Path $Path
            }
        }

    }
    END {
        Write-Verbose "Finished: $($MyInvocation.Mycommand)"
    }
} # enable logging
    } #END
}#function
            #Remove-FslMultiOST
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
        #Write-Log  "Getting ost files from $Path"
function Write-Log {
    [CmdletBinding(DefaultParametersetName = "LOG")]
    Param (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'LOG')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false,
            Position = 1,
            ParameterSetName = 'LOG')]
        [ValidateSet("Error", "Warn", "Info")]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false,
            Position = 2)]
        [string]$Path = "$env:temp\PowershellScript.log",

        [Parameter(Mandatory = $false,
            Position = 3,
            ParameterSetName = 'STARTNEW')]
        [switch]$StartNew,

        [Parameter(Mandatory = $false,
            Position = 4,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'EXCEPTION')]
        [System.Management.Automation.ErrorRecord]$Exception

    )

    BEGIN {
        Set-StrictMode -version Latest
        $expandedParams = $null
        $PSBoundParameters.GetEnumerator() | ForEach-Object { $expandedParams += ' -' + $_.key + ' '; $expandedParams += $_.value }
        Write-Verbose "Starting: $($MyInvocation.MyCommand.Name)$expandedParams"
    }
    PROCESS {

        switch ($PSCmdlet.ParameterSetName) {
            EXCEPTION {
                Write-Log -Level Error -Message $Exception.Exception.Message -Path $Path
                break
            }
            STARTNEW {
                Write-Verbose -Message "Deleting log file $Path if it exists"
                Remove-Item $Path -Force -ErrorAction SilentlyContinue
                Write-Verbose -Message 'Deleted log file if it exists'
                Write-Log 'Starting Logfile' -Path $Path
                break
            }
            LOG {
                Write-Verbose 'Getting Date for our Log File'
                $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Verbose 'Date is $FormattedDate'

                switch ( $Level ) {
                    'Error' { $LevelText = 'ERROR:  '; break }
                    'Warn'  { $LevelText = 'WARNING:'; break }
                    'Info'  { $LevelText = 'INFO:   '; break }
                }

                $logmessage = "$FormattedDate $LevelText $Message"
                Write-Verbose $logmessage

                $logmessage | Add-Content -Path $Path
            }
        }

    }
    END {
        Write-Verbose "Finished: $($MyInvocation.Mycommand)"
    }
} # enable logging
        $ost = Get-ChildItem -Path (Join-Path $Path *.ost) -Recurse
        if ($null -eq $ost) {
            Write-log -level Warn "Did not find any ost files in $Path"
            $ostDelNum = 0
        }
        else {

            $count = $ost | Measure-Object 

            if ($count.Count -gt 1) {

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
                    #Write-Log  "Found $count ost files for $mailbox"
function Write-Log {
    [CmdletBinding(DefaultParametersetName = "LOG")]
    Param (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'LOG')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false,
            Position = 1,
            ParameterSetName = 'LOG')]
        [ValidateSet("Error", "Warn", "Info")]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false,
            Position = 2)]
        [string]$Path = "$env:temp\PowershellScript.log",

        [Parameter(Mandatory = $false,
            Position = 3,
            ParameterSetName = 'STARTNEW')]
        [switch]$StartNew,

        [Parameter(Mandatory = $false,
            Position = 4,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'EXCEPTION')]
        [System.Management.Automation.ErrorRecord]$Exception

    )

    BEGIN {
        Set-StrictMode -version Latest
        $expandedParams = $null
        $PSBoundParameters.GetEnumerator() | ForEach-Object { $expandedParams += ' -' + $_.key + ' '; $expandedParams += $_.value }
        Write-Verbose "Starting: $($MyInvocation.MyCommand.Name)$expandedParams"
    }
    PROCESS {

        switch ($PSCmdlet.ParameterSetName) {
            EXCEPTION {
                Write-Log -Level Error -Message $Exception.Exception.Message -Path $Path
                break
            }
            STARTNEW {
                Write-Verbose -Message "Deleting log file $Path if it exists"
                Remove-Item $Path -Force -ErrorAction SilentlyContinue
                Write-Verbose -Message 'Deleted log file if it exists'
                Write-Log 'Starting Logfile' -Path $Path
                break
            }
            LOG {
                Write-Verbose 'Getting Date for our Log File'
                $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Verbose 'Date is $FormattedDate'

                switch ( $Level ) {
                    'Error' { $LevelText = 'ERROR:  '; break }
                    'Warn'  { $LevelText = 'WARNING:'; break }
                    'Info'  { $LevelText = 'INFO:   '; break }
                }

                $logmessage = "$FormattedDate $LevelText $Message"
                Write-Verbose $logmessage

                $logmessage | Add-Content -Path $Path
            }
        }

    }
    END {
        Write-Verbose "Finished: $($MyInvocation.Mycommand)"
    }
} # enable logging

                    if ($count -gt 1) {

                        $ostDelNum = $count - 1
                        #Write-Log "Deleting $ostDelNum ost files"
function Write-Log {
    [CmdletBinding(DefaultParametersetName = "LOG")]
    Param (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'LOG')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false,
            Position = 1,
            ParameterSetName = 'LOG')]
        [ValidateSet("Error", "Warn", "Info")]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false,
            Position = 2)]
        [string]$Path = "$env:temp\PowershellScript.log",

        [Parameter(Mandatory = $false,
            Position = 3,
            ParameterSetName = 'STARTNEW')]
        [switch]$StartNew,

        [Parameter(Mandatory = $false,
            Position = 4,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'EXCEPTION')]
        [System.Management.Automation.ErrorRecord]$Exception

    )

    BEGIN {
        Set-StrictMode -version Latest
        $expandedParams = $null
        $PSBoundParameters.GetEnumerator() | ForEach-Object { $expandedParams += ' -' + $_.key + ' '; $expandedParams += $_.value }
        Write-Verbose "Starting: $($MyInvocation.MyCommand.Name)$expandedParams"
    }
    PROCESS {

        switch ($PSCmdlet.ParameterSetName) {
            EXCEPTION {
                Write-Log -Level Error -Message $Exception.Exception.Message -Path $Path
                break
            }
            STARTNEW {
                Write-Verbose -Message "Deleting log file $Path if it exists"
                Remove-Item $Path -Force -ErrorAction SilentlyContinue
                Write-Verbose -Message 'Deleted log file if it exists'
                Write-Log 'Starting Logfile' -Path $Path
                break
            }
            LOG {
                Write-Verbose 'Getting Date for our Log File'
                $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Verbose 'Date is $FormattedDate'

                switch ( $Level ) {
                    'Error' { $LevelText = 'ERROR:  '; break }
                    'Warn'  { $LevelText = 'WARNING:'; break }
                    'Info'  { $LevelText = 'INFO:   '; break }
                }

                $logmessage = "$FormattedDate $LevelText $Message"
                Write-Verbose $logmessage

                $logmessage | Add-Content -Path $Path
            }
        }

    }
    END {
        Write-Verbose "Finished: $($MyInvocation.Mycommand)"
    }
} # enable logging
                        try {
                            $latestOst = $mailboxOst | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
                            $mailboxOst | Where-Object {$_.Name -ne $latestOst.Name} | Remove-Item -Force -ErrorAction Stop
                        }
                        catch {
                            #write-log -level Error "Failed to delete ost files in $vhd for $mailbox"
function Write-Log {
    [CmdletBinding(DefaultParametersetName = "LOG")]
    Param (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'LOG')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false,
            Position = 1,
            ParameterSetName = 'LOG')]
        [ValidateSet("Error", "Warn", "Info")]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false,
            Position = 2)]
        [string]$Path = "$env:temp\PowershellScript.log",

        [Parameter(Mandatory = $false,
            Position = 3,
            ParameterSetName = 'STARTNEW')]
        [switch]$StartNew,

        [Parameter(Mandatory = $false,
            Position = 4,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'EXCEPTION')]
        [System.Management.Automation.ErrorRecord]$Exception

    )

    BEGIN {
        Set-StrictMode -version Latest
        $expandedParams = $null
        $PSBoundParameters.GetEnumerator() | ForEach-Object { $expandedParams += ' -' + $_.key + ' '; $expandedParams += $_.value }
        Write-Verbose "Starting: $($MyInvocation.MyCommand.Name)$expandedParams"
    }
    PROCESS {

        switch ($PSCmdlet.ParameterSetName) {
            EXCEPTION {
                Write-Log -Level Error -Message $Exception.Exception.Message -Path $Path
                break
            }
            STARTNEW {
                Write-Verbose -Message "Deleting log file $Path if it exists"
                Remove-Item $Path -Force -ErrorAction SilentlyContinue
                Write-Verbose -Message 'Deleted log file if it exists'
                Write-Log 'Starting Logfile' -Path $Path
                break
            }
            LOG {
                Write-Verbose 'Getting Date for our Log File'
                $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Verbose 'Date is $FormattedDate'

                switch ( $Level ) {
                    'Error' { $LevelText = 'ERROR:  '; break }
                    'Warn'  { $LevelText = 'WARNING:'; break }
                    'Info'  { $LevelText = 'INFO:   '; break }
                }

                $logmessage = "$FormattedDate $LevelText $Message"
                Write-Verbose $logmessage

                $logmessage | Add-Content -Path $Path
            }
        }

    }
    END {
        Write-Verbose "Finished: $($MyInvocation.Mycommand)"
    }
} # enable logging
                        }
                    }
                    else {
                        #Write-Log "Only One ost file found for $mailbox. No action taken"
function Write-Log {
    [CmdletBinding(DefaultParametersetName = "LOG")]
    Param (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName = 'LOG')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false,
            Position = 1,
            ParameterSetName = 'LOG')]
        [ValidateSet("Error", "Warn", "Info")]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false,
            Position = 2)]
        [string]$Path = "$env:temp\PowershellScript.log",

        [Parameter(Mandatory = $false,
            Position = 3,
            ParameterSetName = 'STARTNEW')]
        [switch]$StartNew,

        [Parameter(Mandatory = $false,
            Position = 4,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'EXCEPTION')]
        [System.Management.Automation.ErrorRecord]$Exception

    )

    BEGIN {
        Set-StrictMode -version Latest
        $expandedParams = $null
        $PSBoundParameters.GetEnumerator() | ForEach-Object { $expandedParams += ' -' + $_.key + ' '; $expandedParams += $_.value }
        Write-Verbose "Starting: $($MyInvocation.MyCommand.Name)$expandedParams"
    }
    PROCESS {

        switch ($PSCmdlet.ParameterSetName) {
            EXCEPTION {
                Write-Log -Level Error -Message $Exception.Exception.Message -Path $Path
                break
            }
            STARTNEW {
                Write-Verbose -Message "Deleting log file $Path if it exists"
                Remove-Item $Path -Force -ErrorAction SilentlyContinue
                Write-Verbose -Message 'Deleted log file if it exists'
                Write-Log 'Starting Logfile' -Path $Path
                break
            }
            LOG {
                Write-Verbose 'Getting Date for our Log File'
                $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Write-Verbose 'Date is $FormattedDate'

                switch ( $Level ) {
                    'Error' { $LevelText = 'ERROR:  '; break }
                    'Warn'  { $LevelText = 'WARNING:'; break }
                    'Info'  { $LevelText = 'INFO:   '; break }
                }

                $logmessage = "$FormattedDate $LevelText $Message"
                Write-Verbose $logmessage

                $logmessage | Add-Content -Path $Path
            }
        }

    }
    END {
        Write-Verbose "Finished: $($MyInvocation.Mycommand)"
    }
} # enable logging
                        $ostDelNum = 0
                    }

                }
            }
        }
    } #Process
    END {} #End
}  #function Remove-FslMultiOst
        #endregion

        Write-Log -StartNew -Path $LogPath
        if ($PSVersionTable.PSVersion -lt [version]"5.0.0.0") {
            Write-Log -Level Error 'Powershell must be version 5 or above for this script to run'
            Write-Error 'Powershell must be version 5 or above for this script to run'
            exit
        }
        if ((Get-Module -ListAvailable).Name -notcontains 'Hyper-V') {
            Write-Log -Level Error 'Hyper-V module must be available'
            Write-Error 'Hyper-V module must be available'
            exit
        }
        $PSDefaultParameterValues = @{"Write-Log:Path" = "$LogPath"}
    } #BEGIN
    PROCESS {

        Write-Verbose 'Starting Remove-FslOldOstFile'
        Write-Log 'Starting Remove-FslOldOstFile'
        $vhdList = Get-FslVHD -Path $FolderPath -Verbose:$VerbosePreference
        $vhdToProcess = $vhdList | Where-Object {$_.Attached -eq $false -and $_.FreeSpace -lt $FreeSpace}
        $result = $vhdToProcess.path | Remove-FslOST -Verbose:$VerbosePreference
        Write-Log "Deleted $result ost files from $($vhdToProcess.count) VHD(X)s"
        Write-Verbose 'Finished Remove-FslOldOstFile'
        Write-Log 'Finished Remove-FslOldOstFile'
    } #PROCESS
    END {
        Write-Log 'Script Completed'
    } #END
}#function
