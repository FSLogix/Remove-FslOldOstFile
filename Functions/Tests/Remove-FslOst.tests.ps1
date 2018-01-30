$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$here = Split-Path $here
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe Remove-FslOST {
    BeforeAll {
        . ..\write-Log.ps1
    }
    It 'Should not throw' {
        { Remove-FslOST -VHDPath C:\jimm\temp\1.vhdx } | should not throw
    }
}