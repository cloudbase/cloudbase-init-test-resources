$global:here = Split-Path -Parent $MyInvocation.MyCommand.Path
$ErrorActionPreference = "Stop"

Import-Module "${here}/ini.psm1"

$REG_KEY_WOW_FOLDER = "WOW6432Node\"
$REG_KEY_FOLDER = ""
if ($ENV:TEST_ARCHITECTURE -eq "x86") {
    $REG_KEY_FOLDER = $REG_KEY_WOW_FOLDER
}
$global:CLOUDBASE_INIT_REGISTRY_PATH = "HKLM:\SOFTWARE\${REG_KEY_FOLDER}Cloudbase Solutions\Cloudbase-Init\b9517879-4e93-4a1a-9073-4ae0ddfac27c\Plugins"
$global:CLOUDBASE_INIT_NET_NAME = "cbs_init_eth0"
$global:CLOUDBASE_INIT_NET_STATIC_IP = "10.196.59.2"

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
function before.cloudbaseinit.plugins.common.networkconfig.NetworkConfigPlugin {

    It "a network adapter should not exist" {
        {
            # if the functional test has been already run before,
            # we need to rename the net adapter name to a different name.
            Rename-NetAdapter -Name $global:CLOUDBASE_INIT_NET_NAME -NewName "not_cbs_init0" -ErrorAction SilentlyContinue
        } | Should -Not -Throw
    }

}
function after.cloudbaseinit.plugins.common.networkconfig.NetworkConfigPlugin {
    It "a network adapter should exist and have a proper name" {
        {
            Get-NetAdapter -Name $global:CLOUDBASE_INIT_NET_NAME
            if (!($global:CLOUDBASE_INIT_NET_STATIC_IP -in (Get-NetIPAddress -InterfaceAlias $global:CLOUDBASE_INIT_NET_NAME).IPAddress)) {
                throw "Failed to set ip address on net adapter"
            }
        } | Should -Not -Throw
    }
}

function prepare.empty {
    # NOOP
}

function prepare.openstack {
    pushd "$here/../$($env:CLOUD)"
        $openVpnTapAdapterMacAddress = Prepare-OpenVPNTapAdapter
        $networkTemplateFile = "cloudbase-init-metadata/openstack/latest/network_data.json.template"
        if (Test-path $networkTemplateFile) {
            $networkTemplateFileContent = (Get-Content -Raw $networkTemplateFile)
            $networkTemplateFileContent = $networkTemplateFileContent.Replace("REPLACE_MAC_ADDRESS", $openVpnTapAdapterMacAddress)
            $networkTemplateFileContent | Set-Content "cloudbase-init-metadata/openstack/latest/network_data.json" -Encoding Ascii
            Write-Host $networkTemplateFileContent
        }

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

function prepare.openstack-http {
    prepare.openstack
}

function before.cloudbaseinit.plugins.windows.bootconfig.BCDConfigPlugin {
    # TBD
}
function after.cloudbaseinit.plugins.windows.bootconfig.BCDConfigPlugin {
    # TBD
}

function before.cloudbaseinit.plugins.windows.bootconfig.BootStatusPolicyPlugin {
    # TBD
}
function after.cloudbaseinit.plugins.windows.bootconfig.BootStatusPolicyPlugin {
    # TBD
}

function Prepare-OpenVPNTapAdapter {
    # Use OpenVPN to create a TAP Windows Adapter to be configured.
    # On Github Actions, we cannot use the existing network adapter for verifying the
    # NetworkConfigPlugin, as resetting the same static network config breaks the worker
    # connection to the Github Actions manager, and the action will lose context and
    # timeout.
    $openVpnUrl = "https://build.openvpn.net/downloads/releases/OpenVPN-2.5.10-I601-amd64.msi"
    $wc = New-Object System.Net.WebClient
    $msiFilePath = Join-Path $(pwd) "openvpn.msi"
    $wc.DownloadFile($openVpnUrl, $msiFilePath)
    cmd /c "msiexec.exe -i ${msiFilePath} /qn /norestart /l*v test.log" | Out-Null
    if ($LASTEXITCODE) { throw "Failed to install openvpn" }

    # Refresh the network adapter list to make sure it is properly updated (Windows quirk)
    Get-NetAdapter | Out-Null
    $adapter = Get-NetAdapter -InterfaceDescription "TAP-Windows Adapter V9" | Select-Object -First 1
    if (!$adapter) { throw "Failed to find adapter"}

    # Windows quirk to be able to set static IPs to disconnected network adapters
    Set-ItemProperty -Path "HKLM:\\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\$($adapter.DeviceID)" -Name EnableDHCP -Value 0 | Out-Null

    # A tap device gets created by default after installing OpenVPN.
    # We'll update the network-config template with the according MAC address.
    $currentMacAddress = $adapter.macaddress.Replace("-",":")

    return $currentMacAddress
}

function prepare.nocloud {
    pushd "$here/../$($env:CLOUD)"

        $openVpnTapAdapterMacAddress = Prepare-OpenVPNTapAdapter
        $networkTemplateFile = "cloudbase-init-metadata\network-config.template"
        if (Test-path $networkTemplateFile) {
            $networkTemplateFileContent = (Get-Content -Raw $networkTemplateFile)
            $networkTemplateFileContent = $networkTemplateFileContent.Replace("REPLACE_MAC_ADDRESS", $openVpnTapAdapterMacAddress)
            $networkTemplateFileContent | Set-Content "cloudbase-init-metadata\network-config" -Encoding Ascii
            Write-Host $networkTemplateFileContent
        }

        try {
            Dismount-DiskImage -ErrorAction SilentlyContinue (Resolve-Path "../cloudbase-init-config-drive.iso")
            Remove-Item -Force -ErrorAction SilentlyContinue "../cloudbase-init-config-drive.iso"
        } catch {}
        try {
            & "$here/../bin/mkisofs.exe" -o "../cloudbase-init-config-drive.iso" -ignore-error -ldots -allow-lowercase -allow-multidot -l -publisher "cbsl" -quiet -J -r -V "cidata" "cloudbase-init-metadata" 2>&1
        } catch {}
        Mount-DiskImage -ImagePath (Resolve-Path "../cloudbase-init-config-drive.iso") | Out-Null
        Get-PsDrive | Out-Null

    popd
}

function prepare.proxmox {
    & prepare.nocloud
}

function prepare.vmwareguest {
    pushd "$here/../$($env:CLOUD)"
        $openVpnTapAdapterMacAddress = Prepare-OpenVPNTapAdapter
        $rpcToolMockName = "mock-rpctool"
        $rpcToolPyPath = (Resolve-Path ".\${rpcToolMockName}.py").Path
        if (Test-path $rpcToolPyPath) {
            $rpcToolPyContent = (Get-Content -Raw $rpcToolPyPath)
            $rpcToolPyContent = $rpcToolPyContent.Replace("REPLACE_MAC_ADDRESS", $openVpnTapAdapterMacAddress)
            $rpcToolPyContent | Set-Content $rpcToolPyPath -Encoding Ascii
        }
        # VmwareGuest service relies on a binary called rpctool.exe.
        # This tool returns the metadata or userdata, so we mock it to be as close as
        # possible to the real environment.
        & pip.exe install pyinstaller
        if ($LASTEXITCODE) {
          throw "Failed to install pyinstaller"
        }
        & pyinstaller -F "${rpcToolPyPath}"
        if ($LASTEXITCODE) {
          throw "Failed to create rpctool.exe using pyinstaller"
        }
        $rpcToolPath = (Resolve-Path ".\dist\${rpcToolMockName}.exe").Path
        $metadataServiceConfigFile = (Resolve-Path "cloudbase-init.conf").Path
        Set-IniFileValue -Path $metadataServiceConfigFile -Section "vmwareguestinfo" `
                                      -Key "vmware_rpctool_path" -Value $rpcToolPath
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
    $env:CLOUD | Should -Not -Be $null
    $metadataServiceConfigFile = Resolve-Path "$here/../$($env:CLOUD)/cloudbase-init.conf"
    $pluginList = Get-IniFileValue -Path $metadataServiceConfigFile -Section "DEFAULT" `
                                      -Key "plugins" `
                                      -Default ""
    $pluginList = $pluginList.Split(",")
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
    $env:CLOUD | Should -Not -Be $null
    $metadataServiceConfigFile = Resolve-Path "$here/../$($env:CLOUD)/cloudbase-init.conf"
    $pluginList = Get-IniFileValue -Path $metadataServiceConfigFile -Section "DEFAULT" `
                                      -Key "plugins" `
                                      -Default ""
    $pluginList = $pluginList.Split(",")
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
