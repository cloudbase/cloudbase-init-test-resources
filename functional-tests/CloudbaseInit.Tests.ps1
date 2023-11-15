$global:here = Split-Path -Parent $MyInvocation.MyCommand.Path
$ErrorActionPreference = "Stop"

Import-Module "${here}/ini.psm1"

$global:metadataService = "empty"
$cloudbaseInitRegistryPath = "HKLM:\SOFTWARE\Cloudbase Solutions\Cloudbase-Init"


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

BeforeDiscovery {
    $global:metadataService | Should -Be "empty"
    $metadataServiceConfigFile = Resolve-Path "$here/../$metadataService/cloudbase-init.conf"
    $pluginList = Get-IniFileValue -Path $metadataServiceConfigFile -Section "DEFAULT" `
                                      -Key "plugins" `
                                      -Default ""
    $pluginList = $pluginList.Split(",")
}

Describe "TestVerifyBeforeAllPlugins" {
    foreach ($plugin in $pluginList) {
        if (!$plugin) {
            return
        }
        Context "Verify state for plugin ${plugin}"{
            & "before.${plugin}"

            It "Checks for Registry Key state ${plugin}" {
                $propertyName = "TEST"
                $propertyValue = "NOT_INITIALIZED"
                try {
                    $propertyValue = Get-ItemProperty -Path $cloudbaseInitRegistryPath -Name $propertyNameopertyName -ErrorAction "Stop"
                } catch {
                    $propertyValue = "NOT_EXISTENT"
                }
                $propertyValue | Should -BeExactly "NOT_EXISTENT"
            }
        }
    }
}

Describe "TestVerifyAfterAllPlugins" {
    $pluginList | ForEach-Object {
        $plugin = $_
        if (!$plugin) {
            return
        }
        & "after.${plugin}"

        It "Checks for Registry Key state ${plugin}" {
            $propertyName = "TEST"
            $propertyValue = "NOT_INITIALIZED"
            try {
                $propertyValue = Get-ItemProperty -Path $cloudbaseInitRegistryPath -Name $propertyNameopertyName -ErrorAction "Stop"
            } catch {
                $propertyValue = "NOT_EXISTENT"
            }
            $propertyValue | Should -BeExactly "NOT_EXISTENT"
        }
    }
}
