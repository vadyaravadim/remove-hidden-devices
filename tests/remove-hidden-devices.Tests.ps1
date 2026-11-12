BeforeDiscovery {
    $script:isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

BeforeAll {
    $script:scriptPath = Join-Path $PSScriptRoot '..\remove-hidden-devices.ps1'
    $script:scriptAst = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$null, [ref]$null)

    function Find-ScriptNode([scriptblock]$Predicate) {
        $scriptAst.Find($Predicate, $true)
    }
}

Describe 'PSScriptInfo version placeholder' {
    It 'is exactly .VERSION 0.0.0, the line release.yml stamps' {
        $lines = @(Select-String -LiteralPath $scriptPath -Pattern '^\.VERSION\b' | ForEach-Object Line)
        $lines.Count | Should -Be 1
        $lines[0] | Should -BeExactly '.VERSION 0.0.0'
    }
}

Describe 'the irm | iex rerun forwards -Status to powershell.exe -File' {
    BeforeAll {
        $bootstrap = Find-ScriptNode { param($n) $n -is [System.Management.Automation.Language.IfStatementAst] -and $n.Clauses[0].Item1.Extent.Text -eq '-not $PSCommandPath' }
        $rerun = @($bootstrap.Clauses[0].Item2.Statements | Where-Object { $_.Extent.Text -match '^(\$fwd\s*=|powershell\s)' })
        $rerun.Count | Should -Be 2
        $script:stub = Join-Path $TestDrive 'rerun-stub.ps1'
        Set-Content -LiteralPath $stub -Value 'param([switch]$Status) "Status=$Status"' -Encoding Ascii
        $script:rerunCode = (@('param($Status, $saved)') + @($rerun | ForEach-Object { $_.Extent.Text })) -join "`n"
    }

    It 'binds -Status in the rerun when it is given' {
        & ([scriptblock]::Create($rerunCode)) $true $stub | Should -Be 'Status=True'
    }

    It 'leaves -Status off in the rerun when it is not given' {
        & ([scriptblock]::Create($rerunCode)) $false $stub | Should -Be 'Status=False'
    }
}

Describe 'whole-script run on a machine with one ghost device' {
    BeforeAll {
        $script:copy = Join-Path $TestDrive 'remove-hidden-devices.ps1'
        Copy-Item -LiteralPath $scriptPath -Destination $copy
        $script:stub = Join-Path $TestDrive 'pnputil.cmd'
        Set-Content -LiteralPath $stub -Value "@echo off`r`n>>`"%~dp0pnputil.log`" echo %*`r`nexit /b 0" -Encoding Ascii
        $script:pnputilLog = Join-Path $TestDrive 'pnputil.log'
        $script:savedPath = $env:PATH
        $env:PATH = "$TestDrive;$env:PATH"
        if ((Get-Command pnputil).Source -ne $stub) {
            throw 'the pnputil stub is not first on PATH: the whole-script test would remove real devices on this machine'
        }
        Mock Get-CimInstance { 'mock reached' } -ParameterFilter { $ClassName -eq 'Win32_PesterMockProbe' }
        $probe = Join-Path $TestDrive 'mock-probe.ps1'
        Set-Content -LiteralPath $probe -Value 'Get-CimInstance Win32_PesterMockProbe -ErrorAction SilentlyContinue' -Encoding Ascii
        $probeResult = $null
        try { $probeResult = & $probe } catch { $probeResult = $null }
        if ($probeResult -ne 'mock reached') {
            throw 'Pester mocks do not reach a script run with &: the whole-script tests would touch this machine'
        }
    }

    AfterAll {
        $env:PATH = $savedPath
    }

    BeforeEach {
        Remove-Item -LiteralPath $pnputilLog -ErrorAction SilentlyContinue
        Mock Get-PnpDevice { [pscustomobject]@{ Present = $false; FriendlyName = 'Fake ghost'; InstanceId = 'USB\VID_FAKE\0'; Class = 'USB' } }
        Mock Out-GridView { }
        Mock Read-Host { }
        Mock Start-Process { }
        Mock Start-Sleep { }
        Mock Write-Host { }
    }

    It 'stops before the grid on Windows Server Core' -Skip:(-not $isAdmin) {
        Mock Get-CimInstance { [pscustomobject]@{ BuildNumber = '26100' } } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }
        Mock Get-ItemProperty { [pscustomobject]@{ ServerCore = 1 } } -ParameterFilter { "$Path$LiteralPath" -like '*\Windows NT\CurrentVersion\Server\ServerLevels' }
        & $copy
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { "$Object" -like 'Removing devices needs a Windows edition with a desktop*' }
        Should -Invoke Out-GridView -Times 0 -Exactly -Because 'Server Core cannot open the grid'
        Should -Invoke Read-Host -Times 0 -Exactly -Because 'there is no Y/N fallback any more'
    }

    It 'stops before the grid on a build older than Windows 10 2004' -Skip:(-not $isAdmin) {
        Mock Get-CimInstance { [pscustomobject]@{ BuildNumber = '17763' } } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }
        & $copy
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { "$Object" -like 'Removing devices needs Windows 10 2004*' }
        Should -Invoke Out-GridView -Times 0 -Exactly -Because 'pnputil /remove-device does not exist before build 19041'
    }

    It 'opens the grid on build 19041 with a desktop edition' -Skip:(-not $isAdmin) {
        Mock Get-CimInstance { [pscustomobject]@{ BuildNumber = '19041' } } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }
        & $copy
        Should -Invoke Out-GridView -Times 1 -Exactly
    }

    It 'removes a picked device that is still not present' -Skip:(-not $isAdmin) {
        Mock Get-CimInstance { [pscustomobject]@{ BuildNumber = '19041' } } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }
        Mock Out-GridView { [pscustomobject]@{ Name = 'Fake ghost'; Class = 'USB'; InstanceId = 'USB\VID_FAKE\0' } }
        & $copy
        $calls = @(Get-Content -LiteralPath $pnputilLog)
        $calls.Count | Should -Be 1
        $calls[0] | Should -Match '^/remove-device "?USB\\VID_FAKE\\0"?\s*$'
    }

    It 'skips a picked device that was connected again while the list was open' -Skip:(-not $isAdmin) {
        Mock Get-CimInstance { [pscustomobject]@{ BuildNumber = '19041' } } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }
        Mock Out-GridView { [pscustomobject]@{ Name = 'Fake ghost'; Class = 'USB'; InstanceId = 'USB\VID_FAKE\0' } }
        Mock Get-PnpDevice { [pscustomobject]@{ Present = $true; FriendlyName = 'Fake ghost'; InstanceId = 'USB\VID_FAKE\0'; Class = 'USB' } } -ParameterFilter { $InstanceId -contains 'USB\VID_FAKE\0' }
        & $copy
        $pnputilLog | Should -Not -Exist -Because 'removing a device that is connected again drops its settings'
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { "$Object" -like 'Skipped 1 device(s) that were connected again while the list was open*' }
    }
}

Describe 'PSScriptInfo metadata for the PowerShell Gallery' {
    BeforeAll {
        $script:infoValue = {
            param([string]$Key)
            $line = @(Select-String -LiteralPath $scriptPath -Pattern "^\.$Key\b" | ForEach-Object Line)
            $line.Count | Should -Be 1 -Because "PSScriptInfo has exactly one .$Key line"
            ($line[0] -replace "^\.$Key\s*", '').Trim()
        }
    }

    It 'PSScriptInfo copyright is the LICENSE copyright line' {
        $license = Join-Path $PSScriptRoot '..\LICENSE'
        & $infoValue 'COPYRIGHT' | Should -BeExactly (Get-Content -LiteralPath $license)[2]
    }

    It 'PSScriptInfo tags list PSEdition_Desktop and PSEdition_Core' {
        $tags = (& $infoValue 'TAGS') -split '\s+'
        $tags | Should -Contain 'PSEdition_Desktop'
        $tags | Should -Contain 'PSEdition_Core'
    }

    It 'PSScriptInfo release notes are the CHANGELOG of .PROJECTURI' {
        & $infoValue 'RELEASENOTES' | Should -BeExactly ((& $infoValue 'PROJECTURI') + '/blob/main/CHANGELOG.md')
    }
}
