$global:here = Split-Path -Parent $MyInvocation.MyCommand.Path
$ErrorActionPreference = "Stop"

Import-Module "${here}/ini.psm1"

$global:cloudbaseInitRegistryPath = "HKLM:\SOFTWARE\Cloudbase Solutions\Cloudbase-Init\b9517879-4e93-4a1a-9073-4ae0ddfac27c\Plugins"


function before.cloudbaseinit.plugins.common.mtu.MTUPlugin {
    # NOOP
}
function after.cloudbaseinit.plugins.common.mtu.MTUPlugin {
    # NOOP
}


function before.cloudbaseinit.plugins.windows.ntpclient.NTPClientPlugin {
    It "w32time service should exist" {
        { Get-Service "w32time" -ErrorAction Stop } | Should -Not -Throw
    }
}
function after.cloudbaseinit.plugins.windows.ntpclient.NTPClientPlugin {
    It "w32time service should be running" {
        $status = (Get-Service "w32time" -ErrorAction Stop).Status
        $status | Should -Be "Running"
    }
}

function before.cloudbaseinit.plugins.windows.sanpolicy.SANPolicyPlugin {
    It "Get-StorageSetting should return" {
        { (Get-StorageSetting).NewDiskPolicy } | Should -Not -Throw
    }
}

function after.cloudbaseinit.plugins.windows.sanpolicy.SANPolicyPlugin {
    It "Get-StorageSetting should be OnlineAll" {
        $sanPolicy = (Get-StorageSetting).NewDiskPolicy
        $sanPolicy | Should -Be "OnlineAll"
    }
}

function before.cloudbaseinit.plugins.windows.displayidletimeout.DisplayIdleTimeoutConfigPlugin {
    It "powercfg returns SUB_VIDEO VIDEOIDLE" {
        $powerCfgOut = $(cmd /c 'powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE') `
            | Select-String -Pattern "Current AC Power Setting Index:"
        $powerCfgOut.Matches.Count | Should -Be 1
    }
}
function after.cloudbaseinit.plugins.windows.displayidletimeout.DisplayIdleTimeoutConfigPlugin {
    It "powercfg returns SUB_VIDEO VIDEOIDLE 0" {
        $powerCfgOut = $(cmd /c 'powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE') `
            | Select-String -Pattern "Current AC Power Setting Index: 0x00000000"
        $powerCfgOut.Matches.Count | Should -Be 1
    }
}

function before.cloudbaseinit.plugins.windows.bootconfig.BootStatusPolicyPlugin {
     It "bcdedit returns base identifier" {
        $bcdOut = $(cmd /c 'bcdedit /enum {current}') `
            | Select-String -Pattern "identifier"
        $bcdOut.Matches.Count | Should -Be 1
     }

}
function after.cloudbaseinit.plugins.windows.bootconfig.BootStatusPolicyPlugin {
     It "bcdedit returns ignoreallfailures" {
        $bcdOut = $(cmd /c 'bcdedit /enum {current}') `
            | Select-String -Pattern "ignoreallfailures"
        $bcdOut.Matches.Count | Should -Be 1
     }
}

function before.cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin {

}
function after.cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin {

}
function before.cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin {

}
function after.cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin {

}
function before.cloudbaseinit.plugins.common.userdata.UserDataPlugin {

}
function after.cloudbaseinit.plugins.common.userdata.UserDataPlugin {

}
function before.cloudbaseinit.plugins.windows.winrmlistener.ConfigWinRMListenerPlugin {

}
function after.cloudbaseinit.plugins.windows.winrmlistener.ConfigWinRMListenerPlugin {

}
function before.cloudbaseinit.plugins.common.localscripts.LocalScriptsPlugin {

}
function after.cloudbaseinit.plugins.common.localscripts.LocalScriptsPlugin {

}
function before.cloudbaseinit.plugins.common.trim.TrimConfigPlugin {

}
function after.cloudbaseinit.plugins.common.trim.TrimConfigPlugin {

}
function before.cloudbaseinit.plugins.windows.createuser.CreateUserPlugin {

}
function after.cloudbaseinit.plugins.windows.createuser.CreateUserPlugin {

}

function before.cloudbaseinit.plugins.common.sshpublickeys.SetUserSSHPublicKeysPlugin{

}
function after.cloudbaseinit.plugins.common.sshpublickeys.SetUserSSHPublicKeysPlugin{

}

function before.cloudbaseinit.plugins.common.setuserpassword.SetUserPasswordPlugin {

}
function after.cloudbaseinit.plugins.common.setuserpassword.SetUserPasswordPlugin {

}

function before.cloudbaseinit.plugins.windows.winrmcertificateauth.ConfigWinRMCertificateAuthPlugin {

}
function after.cloudbaseinit.plugins.windows.winrmcertificateauth.ConfigWinRMCertificateAuthPlugin {

}


function prepare.empty {
    # NOOP
}

function prepare.openstack {
    pushd "$here/../$($env:CLOUD)"
        try {
            Dismount-DiskImage -ErrorAction SilentlyContinue (Resolve-Path "../cloudbase-init-config-drive.iso")
            Remove-Item -Force -ErrorAction SilentlyContinue "../cloudbase-init-config-drive.iso"
        } catch {}
        try {
            & "$here/../bin/mkisofs.exe" -o "../cloudbase-init-config-drive.iso" -ignore-error -ldots -allow-lowercase -allow-multidot -l -publisher "cbsl" -quiet -J -r -V "config-2" "cloudbase-init-metadata" 2>&1
        } catch {}
        Mount-DiskImage -ImagePath (Resolve-Path "../cloudbase-init-config-drive.iso") | Out-Null
        Get-PsDrive | Out-Null
    popd
}

BeforeDiscovery {
    $env:CLOUD | Should -Not -Be $null
    $metadataServiceConfigFile = Resolve-Path "$here/../$($env:CLOUD)/cloudbase-init.conf"
    $pluginList = Get-IniFileValue -Path $metadataServiceConfigFile -Section "DEFAULT" `
                                      -Key "plugins" `
                                      -Default ""
    $pluginList = $pluginList.Split(",")
    & "prepare.$($ENV:CLOUD)"
}

Describe "TestVerifyBeforeAllPlugins" {
    Context "Verify state before running plugin" -ForEach $pluginList {
        $plugin = $_
        if (!$plugin) {
            return
        }
        & "before.${plugin}"

        $propertyName = $_.split(".")[-1]
        It "Checks for Registry Key state ${plugin} and property ${propertyName}" {
            $propertyName = $_.split(".")[-1]
            $propertyValue = "NOT_INITIALIZED"
            try {
                $propertyValue = Get-ItemProperty -Path $global:cloudbaseInitRegistryPath -Name $propertyName -ErrorAction "Stop" | Select-Object -ExpandProperty $propertyName
            } catch {
                $propertyValue = "NOT_EXISTENT"
            }
            $propertyValue | Should -BeExactly "NOT_EXISTENT"
        }
    }
}

Describe "TestVerifyAfterAllPlugins" {
    Context "Verify state after running plugin" -ForEach $pluginList {
        $plugin = $_
        if (!$plugin) {
            return
        }
        & "after.${plugin}"

        if ($env:CLOUD -ne "empty") {
            $propertyName = $_.split(".")[-1]
            It "Checks for Registry Key state ${plugin} and property ${propertyName}" {
                $propertyName = $_.split(".")[-1]
                $propertyValue = "NOT_INITIALIZED"
                try {
                    $propertyValue = Get-ItemProperty -Path $global:cloudbaseInitRegistryPath -Name $propertyName -ErrorAction "Stop" | Select-Object -ExpandProperty $propertyName
                } catch {
                    $propertyValue = "NOT_EXISTENT"
                }
                $expectedValue = 1
                # plugins that run at every boot
                if ($propertyName -eq "ExtendVolumesPlugin") {
                    $expectedValue = 2
                }
                # plugins that run in the PRE_METADATA_DISCOVERY or PRE_NETWORKING stage
                if ($propertyName -in @("MTUPlugin", "NTPClientPlugin")) {
                    $expectedValue = "NOT_EXISTENT"
                }
                $propertyValue | Should -BeExactly $expectedValue
            }
        }
    }
}
