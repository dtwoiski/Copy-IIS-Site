 .\1_Copy_IIS_Pools.ps1 -sourceSiteName "Teste.WFM" -newClientName "Cliente" -newSiteName "Cliente.WFM" -newSitePath "C:\inetpub\wwwroot\Cliente\MutantAPP\WWW" -identityUsername "svc" -identityPassword "svc"
 
 .\2_Copy_IIS_Site.ps1 -sourceSiteName "Teste.WFM" -sourceClientName "Teste" -newClientName "Cliente" -newSiteName "Cliente.WFM" -newSitePath "C:\inetpub\wwwroot\Cliente\MutantAPP\WWW" -identityUsername "svc" -identityPassword "svc" -bindingnewSiteName "cliente.com.br"

 .\3_Copy_IIS_Asp_Config.ps1 -sourceSiteName "Teste.WFM" -newSiteName "Cliente.WFM"
