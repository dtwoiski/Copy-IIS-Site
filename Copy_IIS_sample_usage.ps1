 .\1_Copy_IIS_pools.ps1 -sourceSiteName "Teste.WFM" -newClientName "Cliente" -newSiteName "Cliente.WFM" -newSitePath "C:\inetpub\wwwroot\Cliente\MutantAPP\WWW" -identityUsername "svc" -identityPassword "svc"
 

 .\2_Copy_IIS_site.ps1 -sourceSiteName "Teste.WFM" -sourceClientName "Teste" -newClientName "Cliente" -newSiteName "Cliente.WFM" -newSitePath "C:\inetpub\wwwroot\Cliente\MutantAPP\WWW" -identityUsername "svc" -identityPassword "svc" -bindingnewSiteName "cliente.com.br"
