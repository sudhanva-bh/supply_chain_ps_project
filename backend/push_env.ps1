$envPath = ".\.env"
$settings = @("SCM_DO_BUILD_DURING_DEPLOYMENT=true")
foreach($line in Get-Content $envPath) {
    if ($line.Trim() -ne "" -and !$line.StartsWith("#")) {
        $settings += $line.Trim()
    }
}
$argsList = @("webapp", "config", "appsettings", "set", "--resource-group", "SupplyChainBackend", "--name", "supply-chain-agentic-1234", "--settings") + $settings
& az $argsList
