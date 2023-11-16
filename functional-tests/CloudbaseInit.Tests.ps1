$global:here = Split-Path -Parent $MyInvocation.MyCommand.Path
$ErrorActionPreference = "Stop"

Import-Module "${here}/ini.psm1"

$REG_KEY_WOW_FOLDER = "WOW6432Node\"
$REG_KEY_FOLDER = ""
if ($ENV:TEST_ARCHITECTURE -eq "x86") {
    $REG_KEY_FOLDER = $REG_KEY_WOW_FOLDER
}
$global:CLOUDBASE_INIT_REGISTRY_PATH = "HKLM:\SOFTWARE\${REG_KEY_FOLDER}Cloudbase Solutions\Cloudbase-Init\b9517879-4e93-4a1a-9073-4ae0ddfac27c\Plugins"


function before.cloudbaseinit.plugins.common.mtu.MTUPlugin {
    # NOOP
}
function after.cloudbaseinit.plugins.common.mtu.MTUPlugin {
    # NOOP
    # MTU plugin retrieves the data from DHCP and is not available
    # in the test environment
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
    # NOOP
}
function after.cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin {
    # NOOP
    # SetHostNamePlugin needs a reboot and the reboot is not available
    # on the test environment
}

function before.cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin {
    # NOOP
}
function after.cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin {
    # NOOP
    # ExtendVolumesPlugin needs a disk that has empty unpartitioned space,
    # which is not available on the test environment
}

function before.cloudbaseinit.plugins.common.userdata.UserDataPlugin {
    It "UserDataPlugin has a clean environment" {
        {
            $out = net.exe localgroup "windows" 2>&1
            if ($LASTEXITCODE) {
                throw "Group not found"
            }
        } | Should -Throw

        {
            $out = net.exe localgroup "cloud-users" 2>&1
            if ($LASTEXITCODE) {
                throw "Group not found"
            }
        } | Should -Throw

        {
            $out = net.exe user "cloud-config-user" 2>&1
            if ($LASTEXITCODE) {
                throw "User not found"
            }
        } | Should -Throw

        { Get-Content -Raw -Path "c:\test_file" -ErrorAction Stop } | Should -Throw
        { Get-Content -Raw -Path "c:\test_append.ps1" -ErrorAction Stop } | Should -Throw
        { Get-ChildItem -Path "c:\runcmd" -ErrorAction Stop } | Should -Throw
    }
}
function after.cloudbaseinit.plugins.common.userdata.UserDataPlugin {
    It "UserDataPlugin created windows group" {
        {
            $out = net.exe localgroup "windows" 2>&1
            if ($LASTEXITCODE) {
                throw "Group not found"
            }
        } | Should -Not -Throw
    }

    It "UserDataPlugin created cloud-users group" {
        {
            $out = net.exe localgroup "cloud-users" 2>&1
            if ($LASTEXITCODE) {
                throw "Group not found"
            }
        } | Should -Not -Throw
    }

    It "UserDataPlugin created cloud-config-user user" {
        {
            $out = net.exe user "cloud-config-user" 2>&1
            if ($LASTEXITCODE) {
                throw "User not found"
            }
        } | Should -Not -Throw
    }

    It "UserDataPlugin created file c:\test_file" {
        {
            Get-Content -Raw -Path "c:\test_file" -ErrorAction Stop
        } | Should -Not -Throw
    }

    It "UserDataPlugin created file c:\test_append" {
        {
            Get-Content -Raw -Path "c:\test_append.ps1" -ErrorAction Stop
        } | Should -Not -Throw
    }

    It "UserDataPlugin created directory c:\runcmd" {
        {
            Get-ChildItem -Path "c:\runcmd" -ErrorAction Stop
        } | Should -Not -Throw
    }
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
    It "CreateUserPlugin has a clean environment" {
        {
            $out = net.exe user "Admin" 2>&1
            if ($LASTEXITCODE) {
                throw "User not found"
            }
        } | Should -Throw
    }
}
function after.cloudbaseinit.plugins.windows.createuser.CreateUserPlugin {
    It "CreateUserPlugin created Admin user" {
        {
            $out = net.exe user "Admin" 2>&1
            if ($LASTEXITCODE) {
                throw "User not found"
            }
        } | Should -Not -Throw
    }
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
                $propertyValue = Get-ItemProperty -Path $global:CLOUDBASE_INIT_REGISTRY_PATH -Name $propertyName -ErrorAction "Stop" | Select-Object -ExpandProperty $propertyName
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
                    $propertyValue = Get-ItemProperty -Path $global:CLOUDBASE_INIT_REGISTRY_PATH -Name $propertyName -ErrorAction "Stop" | Select-Object -ExpandProperty $propertyName
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
