param (
    [string]$sourceSiteName = "Teste.WFM",  # Name of the source site in IIS
	[string]$sourceClientName = "Teste",
	[string]$newClientName = "Cliente",
	[string]$newSiteName = "Cliente.WFM",  # Name of the new site
	[string]$bindingnewSiteName = "cliente.com.br",	
	[string]$newSitePath = "C:\inetpub\wwwroot\$($newClientName)\MutantAPP\WWW", # Caminho f�sico do novo site
    [string]$identityUsername = "YourIdentityUser",  # Username for identity (parameterized)
    [string]$identityPassword = "YourIdentityPassword"  # Password for identity (parameterized)
)

Import-Module WebAdministration

Reset-IISServerManager -Confirm:$false

# Validar se o site de origem existe
$sourceSite = Get-Item "IIS:\Sites\$($sourceSiteName)" -ErrorAction SilentlyContinue
if (-not $sourceSite) {
    Write-Host "? O site '$($sourceSiteName)' n�o foi encontrado!" -ForegroundColor Red
    exit 1
}

Write-Host "? Criando novo site '$($newSiteName)' com os mesmos bindings e certificado..."
New-WebSite -Name $newSiteName -PhysicalPath $newSitePath | Out-Null
$sourceBindings = Get-WebBinding -Name $sourceSiteName
foreach ($binding in $sourceBindings) {
    New-WebBinding -Name $newSiteName -Protocol $binding.protocol -Port 443 -IPAddress "*" -HostHeader $bindingnewSiteName
}

# Define o pool do site
$newAppPoolName = $sourceSite.applicationPool.Replace($sourceClientName, $newClientName)

Set-ItemProperty "IIS:\Sites\$($newSiteName)" -Name applicationPool -Value $newAppPoolName

# Definir o usu�rio espec�fico
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -PSPath "IIS:\Sites\$($newSiteName)" -Name "userName" -Value "$($identityUsername)"

# Definir a senha (caso necess�rio)
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -PSPath "IIS:\Sites\$($newSiteName)" -Name "password" -Value "$($identityPassword)"


# Copiar diret�rios virtuais
$sourceVDirs = Get-ChildItem "IIS:\Sites\$($sourceSiteName)" | Where-Object { $_.PSIsContainer }
foreach ($vDir in $sourceVDirs) {
    $newVDirPath = "IIS:\Sites\$($newSiteName)\$($vDir.Name)"
    if (-not (Test-Path $newVDirPath)) {
        Write-Host "?? Criando diret�rio virtual '$($vDir.Name)'"
		
		$sourceVDirPath = $vDir.physicalPath
		
		$newVDirPhysicalPath = $sourceVDirPath.Replace($sourceClientName, $newClientName)
		
		Write-Host "? Criando novo diret�rio virtual em $($newVDirPath) [$($newVDirPhysicalPath)]"
		
        New-Item -Path $newVDirPath -Type VirtualDirectory -PhysicalPath $newVDirPhysicalPath
    }
}

# Convers�o de pastas em aplica��es

# Copiar aplica��es e manter suas configura��es
$sourceApps = Get-WebApplication -Site $sourceSiteName
foreach ($app in $sourceApps) {
    $appPath = $app.Path.TrimStart("/")  # Remover a barra inicial para uso correto no novo site
    $newAppPath = "IIS:\Sites\$($newSiteName)\$($appPath)"

    # Determinar Application Pool correto
    $sourceAppPool = $app.applicationPool
    $newAppPoolName = "$($newSiteName)$($sourceAppPool.Substring($sourceSiteName.Length))"

    Write-Host "?? Convertendo '$($appPath)' para aplica��o com o pool '$($newAppPoolName)'..."
    
    # Se j� for um diret�rio virtual, convert�-lo em aplica��o
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$($newSiteName)\$($appPath)" -ApplicationPool $newAppPoolName
	#Set-ItemProperty "IIS:\Sites\$($newSiteName)\$($appPath)" -Name applicationPool -Value $newAppPoolName

}


# Copiar configura��es do ASP Cl�ssico


Write-Host "?? Replica��o conclu�da com sucesso!"
