param (
    [string]$sourceSiteName = "Teste.WFM",  # Name of the source site in IIS
    [string]$newSiteName = "Cliente.WFM"  # Name of the new site
)

Import-Module WebAdministration

Reset-IISServerManager -Confirm:$false

#(Get-WebConfiguration "system.webServer/asp/limits" -PSPath "IIS:\Sites\$sourceSiteName").PSObject.Properties
#(Get-WebConfiguration "system.webServer/asp/session" -PSPath "IIS:\Sites\$sourceSiteName").PSObject.Properties
#(Get-WebConfiguration "system.webServer/asp" -PSPath "IIS:\Sites\$sourceSiteName").PSObject.Properties

Write-Host "?? Copiando configurações de ASP Clássico do site '$sourceSiteName' para '$newSiteName'..."

# Lista de propriedades do ASP Clássico a serem copiadas

$filter = "system.webServer/asp"

$classicAspSettings = @(
    "enableParentPaths",
    "bufferingOn",
    "codePage",
    "lcid",
	"appAllowDebugging",
	"appAllowClientDebug",
	"errorsToNTLog",
	"logErrorRequests",
	"calcLineNumber",
	"scriptErrorMessage",
	"scriptErrorSentToBrowser"
)

foreach ($setting in $classicAspSettings) {
    $value = Get-WebConfigurationProperty -Filter $filter -PSPath "IIS:\Sites\$sourceSiteName" -Name $setting
	
    if ($value) {
        Write-Host "?? Aplicando '$setting' = '$($value.Value)' ao novo site..."
        Set-WebConfigurationProperty -Filter $filter -PSPath "IIS:\Sites\$newSiteName" -Name $setting -Value $value.Value
    } else {
        Write-Host "?? Aviso: A configuração '$setting' não foi encontrada no site de origem." -ForegroundColor Yellow
    }
}

$filter = "system.webServer/asp/limits"

$classicAspSettings = @(
	"bufferingLimit",
    "scriptTimeout",
    "maxRequestEntityAllowed"	
)

foreach ($setting in $classicAspSettings) {
    $value = Get-WebConfigurationProperty -Filter $filter -PSPath "IIS:\Sites\$sourceSiteName" -Name $setting
	
    if ($value) {
        Write-Host "?? Aplicando '$setting' = '$($value.Value)' ao novo site..."
        Set-WebConfigurationProperty -Filter $filter -PSPath "IIS:\Sites\$newSiteName" -Name $setting -Value $value.Value
    } else {
        Write-Host "?? Aviso: A configuração '$setting' não foi encontrada no site de origem." -ForegroundColor Yellow
    }
}

$filter = "system.webServer/asp/session"

$classicAspSettings = @(
	"allowSessionState",
    "timeout",
    "max"	
)


foreach ($setting in $classicAspSettings) {
    $value = Get-WebConfigurationProperty -Filter $filter -PSPath "IIS:\Sites\$sourceSiteName" -Name $setting
	
    if ($value) {
        Write-Host "?? Aplicando '$setting' = '$($value.Value)' ao novo site..."
        Set-WebConfigurationProperty -Filter $filter -PSPath "IIS:\Sites\$newSiteName" -Name $setting -Value $value.Value
    } else {
        Write-Host "?? Aviso: A configuração '$setting' não foi encontrada no site de origem." -ForegroundColor Yellow
    }
}


Write-Host "? Configurações de ASP Clássico copiadas com sucesso!"




#$classicAspSettings = @(
#"system.webServer/asp/enableParentPaths",
#    "system.webServer/asp/scriptTimeout",
#    "system.webServer/asp/session.allowSessionState",
#    "system.webServer/asp/session.timeout",
#    "system.webServer/asp/bufferingOn",
#    "system.webServer/asp/codePage",
#    "system.webServer/asp/lcid",
#    "system.webServer/asp/errorsScriptErrorSentToBrowser",
#    "system.webServer/asp/scriptErrorMessage",
#    "system.webServer/asp/scriptFileCacheSize",
#    "system.webServer/asp/maxRequestEntityAllowed",
#    "system.webServer/asp/executeInMta"
#)