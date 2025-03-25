param (
    [string]$sourceSiteName = "Teste.WFM",  # Name of the source site in IIS
	[string]$sourceClientName = "Teste",
	[string]$newClientName = "Cliente",
	[string]$newSiteName = "Cliente.WFM",  # Name of the new site
	[string]$bindingnewSiteName = "cliente.com.br",	
	[string]$newSitePath = "C:\inetpub\wwwroot\$($newClientName)\MutantAPP\WWW", # Caminho físico do novo site
    [string]$identityUsername = "YourIdentityUser",  # Username for identity (parameterized)
    [string]$identityPassword = "YourIdentityPassword"  # Password for identity (parameterized)
)

Import-Module WebAdministration

Reset-IISServerManager -Confirm:$false

# Validar se o site de origem existe
$sourceSite = Get-Item "IIS:\Sites\$($sourceSiteName)" -ErrorAction SilentlyContinue
if (-not $sourceSite) {
    Write-Host "? O site '$($sourceSiteName)' não foi encontrado!" -ForegroundColor Red
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

# Definir o usuário específico
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -PSPath "IIS:\Sites\$($newSiteName)" -Name "userName" -Value "$($identityUsername)"

# Definir a senha (caso necessário)
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -PSPath "IIS:\Sites\$($newSiteName)" -Name "password" -Value "$($identityPassword)"


# Copiar diretórios virtuais
$sourceVDirs = Get-ChildItem "IIS:\Sites\$($sourceSiteName)" | Where-Object { $_.PSIsContainer }
foreach ($vDir in $sourceVDirs) {
    $newVDirPath = "IIS:\Sites\$($newSiteName)\$($vDir.Name)"
    if (-not (Test-Path $newVDirPath)) {
        Write-Host "?? Criando diretório virtual '$($vDir.Name)'"
		
		$sourceVDirPath = $vDir.physicalPath
		
		$newVDirPhysicalPath = $sourceVDirPath.Replace($sourceClientName, $newClientName)
		
		Write-Host "? Criando novo diretório virtual em $($newVDirPath) [$($newVDirPhysicalPath)]"
		
        New-Item -Path $newVDirPath -Type VirtualDirectory -PhysicalPath $newVDirPhysicalPath
    }
}

# Conversão de pastas em aplicações

# Copiar aplicações e manter suas configurações
$sourceApps = Get-WebApplication -Site $sourceSiteName
foreach ($app in $sourceApps) {
    $appPath = $app.Path.TrimStart("/")  # Remover a barra inicial para uso correto no novo site
    $newAppPath = "IIS:\Sites\$($newSiteName)\$($appPath)"

    # Determinar Application Pool correto
    $sourceAppPool = $app.applicationPool
    $newAppPoolName = "$($newSiteName)$($sourceAppPool.Substring($sourceSiteName.Length))"

    Write-Host "?? Convertendo '$($appPath)' para aplicação com o pool '$($newAppPoolName)'..."
    
    # Se já for um diretório virtual, convertê-lo em aplicação
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$($newSiteName)\$($appPath)" -ApplicationPool $newAppPoolName
	#Set-ItemProperty "IIS:\Sites\$($newSiteName)\$($appPath)" -Name applicationPool -Value $newAppPoolName

}


# Copiar configurações do ASP Clássico


Write-Host "?? Replicação concluída com sucesso!"
