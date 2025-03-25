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

Write-Host "?? Replicando Application Pools para o site '$($sourceSiteName)'..."

# Copiar os pools de aplicação para o novo site
$sourceAppPools = Get-IISAppPool | Where-Object { $_.Name -like "$($sourceSiteName)*" }  # Filtra pools que comecam com o nome Teste.WFM

foreach ($sourceAppPool in $sourceAppPools) {
	
    # Extraímos a parte do nome do pool que corresponde à funcionalidade
    $poolFunctionality = $sourceAppPool.Name.Substring($sourceSiteName.Length)  # Ex: 'autenticacao' do pool 'nebraska.dev.com.autenticacao'

    # Substituir o nome do site de origem pelo nome do novo site no nome do pool
    $newAppPoolName = "$($newSiteName)$($poolFunctionality)"  # Ex: 'nomesitenovo.dev.com.autenticacao'

    # Verifica se o pool já existe
    if (Get-IISAppPool -Name $newAppPoolName -ErrorAction SilentlyContinue) {
        Write-Host "?? O Application Pool '$($newAppPoolName)' já existe. Não será criado um novo."
    } else {
        # Criar um novo Application Pool se não existir
        Write-Host "?? Criando Application Pool '$($newAppPoolName)' baseado no pool '$($sourceAppPool.Name)'"

        # Criar o pool de aplicativos baseado nas configurações do pool original
        New-WebAppPool -Name $newAppPoolName
        Start-Sleep -Seconds 2

		#$credentials = (Get-Credential -Message "Please enter the Login credentials including Domain Name").GetNetworkCredential()

		# Configurar a identidade do pool
        Set-ItemProperty "IIS:\AppPools\$($newAppPoolName)" -Name "processModel.identityType" -Value 3
        Set-ItemProperty "IIS:\AppPools\$($newAppPoolName)" -Name "processModel.userName" -Value $identityUsername
        Set-ItemProperty "IIS:\AppPools\$($newAppPoolName)" -Name "processModel.password" -Value $identityPassword

        # Copiar as propriedades do pool original
        Set-ItemProperty "IIS:\AppPools\$($newAppPoolName)" -Name managedRuntimeVersion -Value $sourceAppPool.managedRuntimeVersion
        Set-ItemProperty "IIS:\AppPools\$($newAppPoolName)" -Name enable32BitAppOnWin64 -Value $sourceAppPool.enable32BitAppOnWin64
		
		$testpool = get-item iis:\apppools\$($newAppPoolName);
		$testpool.processModel.userName = $un;
		$testpool.processModel.password = $pw;
		$testpool.processModel.identityType = 3;
		$testpool.managedRuntimeVersion =  $sourceAppPool.managedRuntimeVersion;
		$testpool.enable32BitAppOnWin64 = $sourceAppPool.enable32BitAppOnWin64;
	
		$testpool | Set-Item
		$testpool.Stop();
		$testpool.Start();


        Write-Host "? Application Pool '$($newAppPoolName)' criado com base no pool '$($sourceAppPool.Name)'"
    }
}

Write-Host "?? Todos os Application Pools foram verificados e copiados com sucesso!"

