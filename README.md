## cloudbase-init-test-resources repostitory contains Pester based functional tests for:

  * cloudbase-init https://github.com/cloudbase/cloudbase-init.

For Pester, see: https://pester.dev.


## How to run

### Install Pester

```powershell
# run from an administrative powershell
Install-Module -Force -AllowClobber -Confirm:$false "Pester" -SkipPublisherCheck
```

### Run functional tests for OpenStack

### DO NOT RUN ON A LIVE PRODUCTION ENVIRONMENT, AS IT CAN DESTROY DATA OR, REBOOT MACHINE!!!

### These functional tests are meant to be run in short lived execution environments, like Github Actions sandboxes/containers 

See a real world example here: https://github.com/cloudbase/cloudbase-init/blob/master/.github/workflows/cloudbase_init_tests.yml#L85.

```powershell
$ENV:CLOUD = "openstack"

# Run functional tests before cloudbase-init is run
# These tests make sure that the environment is clean
# Also, this invocation sets up the correct metadata setup
Invoke-Pester functional-tests -Output Detailed -FullNameFilter TestVerifyBeforeAllPlugins

# Run cloudbase-init using a config drive based approach
try {
    & cmd /c "cloudbase-init.exe --noreset_service_password --config-file ./test-resources/openstack/cloudbase-init.conf 2>&1" | Tee-Object -FilePath cloudbase-init.log
} catch {}
        
# Ensure there are no plugin errors
$errors = $(cat ./cloudbase-init.log | Where-Object {$_ -like "*error*"})
$pluginExecution = $(cat ./cloudbase-init.log | Where-Object {$_ -like "*Plugins execution done*"})
if ($errors -or !$pluginExecution) {
    exit 1
}

# Run functional tests after cloudbase-init is run
# These tests make sure that the environment is changed according to the specifications
Invoke-Pester test-resources/functional-tests -Output Detailed -FullNameFilter TestVerifyAfterAllPlugins
```
