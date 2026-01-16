@echo off
chcp 65001 >nul
title Ferramenta de Suporte TI - v2.0

:: ===============================================================
::  FERRAMENTA DE SUPORTE TÉCNICO EM INFORMÁTICA
::  Versão: 2.0
::  Desenvolvido para técnicos de suporte
:: ===============================================================

setlocal EnableExtensions EnableDelayedExpansion

:: ---------------------[ Configuração de Log ]---------------------
set "YY=%DATE:~6,4%"
set "MM=%DATE:~3,2%"
set "DD=%DATE:~0,2%"
set "HH=%TIME:~0,2%"
set "MIN=%TIME:~3,2%"
set "SS=%TIME:~6,2%"

if "%HH:~0,1%"==" " set "HH=0%HH:~1,1%"

set "LOGFILE=%~dp0logs\log_%YY%%MM%%DD%_%HH%%MIN%%SS%.txt"
if not exist "%~dp0logs" mkdir "%~dp0logs"

:: Muda para o diretório do script e inicia o menu
cd /d "%~dp0" 2>nul
goto :MENU

:: ---------------------[ Funções Utilitárias ]---------------------

:LogEcho
if "%~1"=="" goto :eof
echo %*
echo [%date% %time%] %* >> "%LOGFILE%"
goto :eof

:CheckAdmin
fltmc >nul 2>&1
if errorlevel 1 ( 
    set "_IS_ADMIN=0"
    set "_ADMIN_TEXT=❌ Modo Normal"
    set "_ADMIN_COLOR=0C"
) else ( 
    set "_IS_ADMIN=1"
    set "_ADMIN_TEXT=✅ Administrador"
    set "_ADMIN_COLOR=0A"
)
goto :eof

:ElevateSelf
call :LogEcho "Solicitando elevacao de privilegios..."
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
if errorlevel 1 (
    echo ERRO: Nao foi possivel elevar privilegios.
    pause
)
goto :eof

:PauseMenu
echo.
echo Pressione qualquer tecla para voltar ao menu...
pause >nul
goto :eof

:ConfirmAction
set "_CONFIRM=N"
set /p "_CONFIRM=%~1 (S/N): "
if /I "%_CONFIRM%"=="S" ( set "_CONFIRM=Y" ) else ( set "_CONFIRM=N" )
goto :eof

:CreateBackup
:: Cria backup de configurações antes de operações críticas
:: Parâmetro: %1 = Tipo (REDE, FIREWALL, APPS)
set "BACKUP_TYPE=%~1"
set "BACKUP_DIR=%~dp0backups"
set "BACKUP_FILE=%BACKUP_DIR%\backup_%BACKUP_TYPE%_%YY%%MM%%DD%_%HH%%MIN%%SS%.txt"

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo.
echo 📦 Criando backup de segurança...
call :LogEcho "Criando backup: %BACKUP_TYPE%"

echo ================================================== > "%BACKUP_FILE%"
echo BACKUP AUTOMÁTICO - FERRAMENTA DE SUPORTE TI >> "%BACKUP_FILE%"
echo ================================================== >> "%BACKUP_FILE%"
echo Tipo: %BACKUP_TYPE% >> "%BACKUP_FILE%"
echo Data: %DATE% %TIME% >> "%BACKUP_FILE%"
echo Sistema: %COMPUTERNAME% >> "%BACKUP_FILE%"
echo Usuário: %USERNAME% >> "%BACKUP_FILE%"
echo ================================================== >> "%BACKUP_FILE%"
echo. >> "%BACKUP_FILE%"

if /I "%BACKUP_TYPE%"=="REDE" (
    echo [CONFIGURAÇÕES DE REDE] >> "%BACKUP_FILE%"
    ipconfig /all >> "%BACKUP_FILE%"
    echo. >> "%BACKUP_FILE%"
    echo [ADAPTADORES] >> "%BACKUP_FILE%"
    netsh interface show interface >> "%BACKUP_FILE%"
    echo. >> "%BACKUP_FILE%"
    echo [ROTAS] >> "%BACKUP_FILE%"
    route print >> "%BACKUP_FILE%"
    echo. >> "%BACKUP_FILE%"
    echo [TABELA ARP] >> "%BACKUP_FILE%"
    arp -a >> "%BACKUP_FILE%"
)

if /I "%BACKUP_TYPE%"=="FIREWALL" (
    echo [ESTADO DO FIREWALL] >> "%BACKUP_FILE%"
    netsh advfirewall show allprofiles >> "%BACKUP_FILE%"
    echo. >> "%BACKUP_FILE%"
    echo [REGRAS DO FIREWALL] >> "%BACKUP_FILE%"
    netsh advfirewall firewall show rule name=all >> "%BACKUP_FILE%"
)

if /I "%BACKUP_TYPE%"=="APPS" (
    echo [APLICATIVOS NATIVOS INSTALADOS] >> "%BACKUP_FILE%"
    powershell -NoProfile -Command "Get-AppxPackage | Select-Object Name, Version, PackageFullName | Format-List" >> "%BACKUP_FILE%"
)

echo. >> "%BACKUP_FILE%"
echo ================================================== >> "%BACKUP_FILE%"
echo FIM DO BACKUP >> "%BACKUP_FILE%"
echo ================================================== >> "%BACKUP_FILE%"

echo ✅ Backup criado com sucesso!
echo 📄 Arquivo: %BACKUP_FILE%
call :LogEcho "Backup salvo em: %BACKUP_FILE%"
set "LAST_BACKUP=%BACKUP_FILE%"
goto :eof

:ListBackups
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                 BACKUPS DISPONÍVEIS                           ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

if not exist "%~dp0backups\backup_*.txt" (
    echo ⚠️  Nenhum backup encontrado.
    echo.
    echo ℹ️  Backups são criados automaticamente antes de operações críticas.
    goto :eof
)

echo Lista de backups criados:
echo ───────────────────────────────────────────────────────────────
echo.

set "BACKUP_COUNT=0"
for %%F in ("%~dp0backups\backup_*.txt") do (
    set /a BACKUP_COUNT+=1
    echo [!BACKUP_COUNT!] %%~nxF
    echo     Tamanho: %%~zF bytes
    echo     Data: %%~tF
    echo.
)

echo ───────────────────────────────────────────────────────────────
echo Total: %BACKUP_COUNT% backup(s) encontrado(s)
echo.
goto :eof

:RestoreBackup
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║              RESTAURAR BACKUP                                 ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

if not exist "%~dp0backups\backup_*.txt" (
    echo ⚠️  Nenhum backup disponível para restaurar.
    goto :eof
)

call :ListBackups

echo.
echo Selecione o backup para visualizar:
set "BACKUP_NUM="
set /p "BACKUP_NUM=Digite o número do backup (0 para cancelar): "

if "%BACKUP_NUM%"=="0" goto :eof

set "BACKUP_INDEX=0"
for %%F in ("%~dp0backups\backup_*.txt") do (
    set /a BACKUP_INDEX+=1
    if "!BACKUP_INDEX!"=="%BACKUP_NUM%" (
        cls
        echo ╔═══════════════════════════════════════════════════════════════╗
        echo ║              CONTEÚDO DO BACKUP                               ║
        echo ╚═══════════════════════════════════════════════════════════════╝
        echo.
        echo Arquivo: %%~nxF
        echo ───────────────────────────────────────────────────────────────
        type "%%F"
        echo.
        echo ───────────────────────────────────────────────────────────────
        echo.
        echo ℹ️  Este backup contém as configurações salvas.
        echo ℹ️  Você pode usar essas informações para restaurar manualmente.
        echo.
        call :PauseMenu
        goto :eof
    )
)

echo ❌ Número inválido!
timeout /t 2 >nul
goto :eof

:PrintHeader
cls
color %_ADMIN_COLOR%
echo.
echo ╔═══════════════════════════════════════════════════════════════════════╗
echo ║           FERRAMENTA DE SUPORTE TÉCNICO TI - v2.0                     ║
echo ╚═══════════════════════════════════════════════════════════════════════╝
echo.
echo  Sistema: %COMPUTERNAME% ^| Usuário: %USERNAME% ^| Status: %_ADMIN_TEXT%
echo  Log: %LOGFILE%
echo ═══════════════════════════════════════════════════════════════════════
goto :eof

:: ---------------------[ Menu Principal ]---------------------

:MENU
cd /d "%~dp0"
call :CheckAdmin
call :PrintHeader

echo.
echo  [G]  Iniciar Interface Gráfica (GUI)
echo.
echo  🖥️  DIAGNÓSTICO E OTIMIZAÇÃO
echo  ───────────────────────────────────────────────────────────────────
echo  [1]  Limpeza Completa (Temporários + Cache + Disco)
echo  [2]  Reparo do Sistema (DISM + SFC) [Admin]
echo  [3]  Otimizar Disco C: (Defrag/TRIM) [Admin]
echo  [4]  Teste de Desempenho de Disco
echo  [5]  Gerar Relatório Completo do Sistema
echo.
echo  🌐 REDE E CONECTIVIDADE
echo  ───────────────────────────────────────────────────────────────────
echo  [6]  Diagnóstico de Internet (Ping + DNS + IP)
echo  [7]  Reset COMPLETO de Rede [Admin]
echo  [8]  Flush DNS
echo  [9]  Ver Configurações de IP Detalhadas
echo  [10] Teste de Velocidade (Speedtest Online)
echo  [11] Mostrar Adaptadores de Rede
echo  [12] Testar Conectividade (8.8.8.8, 1.1.1.1, Google)
echo.
echo  🔒 SEGURANÇA E SISTEMA
echo  ───────────────────────────────────────────────────────────────────
echo  [13] Criar Ponto de Restauração [Admin]
echo  [14] Desativar Firewall [Admin] ⚠️
echo  [15] Ativar Firewall [Admin]
echo  [16] Logs de Eventos do Sistema
echo  [17] Verificar Atualizações Pendentes
echo.
echo  🛠️  UTILITÁRIOS AVANÇADOS
echo  ───────────────────────────────────────────────────────────────────
echo  [18] Abrir CMD como Administrador
echo  [19] Gerenciador de Tarefas
echo  [20] Atualizar Todos Pacotes (winget)
echo  [21] Forçar Atualização de Políticas (gpupdate)
echo  [22] Listar Aplicativos Nativos Windows
echo  [23] Remover Aplicativo Nativo
echo  [24] Gerar Log do Windows Update (Desktop)
echo  [25] Abrir Ferramentas do Sistema (Menu)
echo.
echo  📊 RELATÓRIOS E INFO
echo  ───────────────────────────────────────────────────────────────────
echo  [26] Informações Completas do Sistema
echo  [27] Relatório de Hardware (CPU, RAM, Disco)
echo  [28] Verificar Saúde da Bateria (Laptops)
echo  [29] Listar Programas Instalados
echo.
echo  💾 BACKUP E RESTAURAÇÃO
echo  ───────────────────────────────────────────────────────────────────
echo  [30] Listar Backups Disponíveis
echo  [31] Visualizar/Restaurar Backup
echo  [32] Limpar Backups Antigos
echo.
echo   SAIR
echo  ───────────────────────────────────────────────────────────────────
echo  [0]  Sair da Ferramenta
echo ═══════════════════════════════════════════════════════════════════════
echo.
set "OP="
set /p "OP=Escolha uma opcao: "

if "%OP%"=="" goto :MENU
if /I "%OP%"=="G" goto :START_GUI
for /f "delims=0123456789" %%A in ("%OP%") do goto :MENU

call :LogEcho "Opcao selecionada: %OP%"

:: Rotas do menu
if "%OP%"=="1"  goto :LIMPEZA_COMPLETA
if "%OP%"=="2"  goto :REPARO_SISTEMA
if "%OP%"=="3"  goto :OTIMIZAR_DISCO
if "%OP%"=="4"  goto :TESTE_DISCO
if "%OP%"=="5"  goto :RELATORIO_SISTEMA

if "%OP%"=="6"  goto :DIAGNOSTICO_INTERNET
if "%OP%"=="7"  goto :RESET_REDE
if "%OP%"=="8"  goto :FLUSH_DNS
if "%OP%"=="9"  goto :VER_IP
if "%OP%"=="10" goto :SPEEDTEST
if "%OP%"=="11" goto :ADAPTADORES_REDE
if "%OP%"=="12" goto :TESTE_CONECTIVIDADE

if "%OP%"=="13" goto :PONTO_RESTAURACAO
if "%OP%"=="14" goto :FIREWALL_OFF
if "%OP%"=="15" goto :FIREWALL_ON
if "%OP%"=="16" goto :LOGS_EVENTOS
if "%OP%"=="17" goto :VERIFICAR_UPDATES

if "%OP%"=="18" goto :CMD_ADMIN
if "%OP%"=="19" goto :TASK_MANAGER
if "%OP%"=="20" goto :WINGET_UPDATE
if "%OP%"=="21" goto :GPUPDATE
if "%OP%"=="22" goto :LISTAR_APPS
if "%OP%"=="23" goto :REMOVER_APP
if "%OP%"=="24" goto :LOG_WUPDATE
if "%OP%"=="25" goto :FERRAMENTAS_SISTEMA

if "%OP%"=="26" goto :INFO_SISTEMA
if "%OP%"=="27" goto :RELATORIO_HARDWARE
if "%OP%"=="28" goto :SAUDE_BATERIA
if "%OP%"=="29" goto :PROGRAMAS_INSTALADOS

if "%OP%"=="30" goto :MENU_LIST_BACKUPS
if "%OP%"=="31" goto :MENU_RESTORE_BACKUP
if "%OP%"=="32" goto :LIMPAR_BACKUPS

if "%OP%"=="0"  goto :SAIR

echo Opcao invalida!
timeout /t 2 >nul
goto :MENU

:: =====================================================================
::                    IMPLEMENTAÇÕES DAS FUNÇÕES
:: =====================================================================

:: ---------------------[ Diagnóstico e Otimização ]---------------------

:LIMPEZA_COMPLETA
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║               LIMPEZA COMPLETA DO SISTEMA                     ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
call :LogEcho "Iniciando limpeza completa..."

echo [1/5] Limpando arquivos temporarios do usuario...
del /q /f /s "%TEMP%\*" >nul 2>&1
call :LogEcho "Temporarios do usuario limpos"

echo [2/5] Limpando arquivos temporarios do sistema...
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
call :LogEcho "Temporarios do sistema limpos"

echo [3/5] Limpando cache do Windows Explorer...
del /q /f /s "%LOCALAPPDATA%\Microsoft\Windows\Explorer\*" >nul 2>&1
call :LogEcho "Cache do Explorer limpo"

echo [4/5] Limpando prefetch...
del /q /f "C:\Windows\Prefetch\*" >nul 2>&1
call :LogEcho "Prefetch limpo"

echo [5/5] Executando Limpeza de Disco do Windows...
cleanmgr /sageset:65535 >nul 2>&1
start /wait cleanmgr /sagerun:65535

echo.
echo ✅ Limpeza completa finalizada!
call :LogEcho "Limpeza completa concluida"
call :PauseMenu
goto :MENU

:REPARO_SISTEMA
call :PrintHeader
if not "%_IS_ADMIN%"=="1" (
    echo.
    echo ⚠️  Esta funcao requer privilegios de Administrador!
    echo.
    call :ConfirmAction "Deseja reabrir a ferramenta como Administrador"
    if /I "%_CONFIRM%"=="Y" ( call :ElevateSelf )
    call :PauseMenu
    goto :MENU
)

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║            REPARO COMPLETO DO SISTEMA WINDOWS                 ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo ⚠️  Este processo pode demorar bastante tempo!
echo.
call :ConfirmAction "Deseja continuar com o reparo"
if /I not "%_CONFIRM%"=="Y" goto :MENU

call :LogEcho "Iniciando reparo do sistema..."
echo.
echo [1/2] Verificando e reparando imagem do Windows (DISM)...
DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /RestoreHealth

echo.
echo [2/2] Verificando integridade dos arquivos do sistema (SFC)...
sfc /scannow

echo.
echo ✅ Reparos concluidos!
echo ℹ️  RECOMENDAÇÃO: Reinicie o computador para aplicar todas as correções.
call :LogEcho "Reparo do sistema concluido"
call :PauseMenu
goto :MENU

:OTIMIZAR_DISCO
call :PrintHeader
if not "%_IS_ADMIN%"=="1" (
    echo.
    echo ⚠️  Esta funcao requer privilegios de Administrador!
    call :PauseMenu
    goto :MENU
)

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                OTIMIZAÇÃO DO DISCO C:                         ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
call :ConfirmAction "Deseja otimizar/desfragmentar o disco C: agora"
if /I not "%_CONFIRM%"=="Y" goto :MENU

echo.
call :LogEcho "Otimizando disco C:..."
defrag C: /O /U /V

echo.
echo ✅ Otimizacao concluida!
call :PauseMenu
goto :MENU

:TESTE_DISCO
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║            TESTE DE DESEMPENHO DO DISCO                       ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
call :LogEcho "Executando teste de desempenho do disco..."
winsat disk
echo.
echo ✅ Teste concluido!
call :PauseMenu
goto :MENU

:RELATORIO_SISTEMA
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║          GERANDO RELATÓRIO COMPLETO DO SISTEMA                ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

set "REPORT_FILE=%~dp0logs\relatorio_sistema_%YY%%MM%%DD%_%HH%%MIN%%SS%.txt"

echo Gerando relatorio em: %REPORT_FILE%
echo.

echo ============================================ > "%REPORT_FILE%"
echo RELATÓRIO DO SISTEMA - %DATE% %TIME% >> "%REPORT_FILE%"
echo ============================================ >> "%REPORT_FILE%"
echo. >> "%REPORT_FILE%"

echo [1/4] Informacoes do sistema...
systeminfo >> "%REPORT_FILE%"

echo [2/4] Configuracoes de rede...
echo. >> "%REPORT_FILE%"
echo ============================================ >> "%REPORT_FILE%"
echo CONFIGURAÇÕES DE REDE >> "%REPORT_FILE%"
echo ============================================ >> "%REPORT_FILE%"
ipconfig /all >> "%REPORT_FILE%"

echo [3/4] Processos em execucao...
echo. >> "%REPORT_FILE%"
echo ============================================ >> "%REPORT_FILE%"
echo PROCESSOS EM EXECUÇÃO >> "%REPORT_FILE%"
echo ============================================ >> "%REPORT_FILE%"
tasklist /v >> "%REPORT_FILE%"

echo [4/4] Servicos do Windows...
echo. >> "%REPORT_FILE%"
echo ============================================ >> "%REPORT_FILE%"
echo SERVIÇOS DO WINDOWS >> "%REPORT_FILE%"
echo ============================================ >> "%REPORT_FILE%"
sc query >> "%REPORT_FILE%"

echo.
echo ✅ Relatorio gerado com sucesso!
echo 📄 Arquivo: %REPORT_FILE%
echo.
call :ConfirmAction "Deseja abrir o relatorio agora"
if /I "%_CONFIRM%"=="Y" notepad "%REPORT_FILE%"
call :PauseMenu
goto :MENU

:: ---------------------[ Rede e Conectividade ]---------------------

:DIAGNOSTICO_INTERNET
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║          DIAGNÓSTICO COMPLETO DE INTERNET                     ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

echo [1/5] Testando DNS primário (1.1.1.1)...
ping -n 4 1.1.1.1

echo.
echo [2/5] Testando DNS secundário (8.8.8.8)...
ping -n 4 8.8.8.8

echo.
echo [3/5] Testando resolução de nomes (google.com)...
ping -n 4 google.com

echo.
echo [4/5] Limpando cache DNS...
ipconfig /flushdns

echo.
echo [5/5] Renovando configuração IP...
ipconfig /release
ipconfig /renew

echo.
echo ✅ Diagnóstico concluído!
call :PauseMenu
goto :MENU

:RESET_REDE
call :PrintHeader
if not "%_IS_ADMIN%"=="1" (
    echo.
    echo ⚠️  Esta funcao requer privilegios de Administrador!
    call :PauseMenu
    goto :MENU
)

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║              RESET COMPLETO DE REDE                           ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo ⚠️  ATENÇÃO: Este processo irá resetar TODAS as configurações de rede!
echo ⚠️  Você perderá a conexão temporariamente.
echo ⚠️  Um REINÍCIO do computador será NECESSÁRIO após o processo.
echo.
call :ConfirmAction "Tem CERTEZA que deseja continuar"
if /I not "%_CONFIRM%"=="Y" goto :MENU

:: Criar backup antes de modificar configurações
call :CreateBackup REDE

echo.
echo [1/6] Resetando Winsock...
netsh winsock reset

echo [2/6] Resetando TCP/IP...
netsh int ip reset

echo [3/6] Resetando Firewall...
netsh advfirewall reset

echo [4/6] Limpando cache DNS...
ipconfig /flushdns

echo [5/6] Limpando cache ARP...
netsh interface ip delete arpcache

echo [6/6] Renovando IP...
ipconfig /release
ipconfig /renew

echo.
echo ✅ Reset de rede concluído!
echo ⚠️  REINICIE o computador para aplicar todas as mudanças.
echo.
call :ConfirmAction "Deseja reiniciar AGORA"
if /I "%_CONFIRM%"=="Y" shutdown /r /t 10 /c "Reiniciando para aplicar configuracoes de rede..."
call :PauseMenu
goto :MENU

:FLUSH_DNS
call :PrintHeader
echo.
echo Limpando cache DNS...
ipconfig /flushdns
echo.
echo ✅ Cache DNS limpo com sucesso!
call :PauseMenu
goto :MENU

:VER_IP
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║         CONFIGURAÇÕES DETALHADAS DE IP                        ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
ipconfig /all
echo.
echo ═══════════════════════════════════════════════════════════════
echo Resumo (IPv4, DNS, DHCP):
ipconfig /all | findstr /I "IPv4 DNS DHCP Gateway"
call :PauseMenu
goto :MENU

:SPEEDTEST
call :PrintHeader
echo.
echo Abrindo Speedtest by Ookla no navegador...
start "" https://www.speedtest.net
echo.
echo ✅ Página aberta! Execute o teste no navegador.
call :PauseMenu
goto :MENU

:ADAPTADORES_REDE
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║            ADAPTADORES DE REDE                                ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
netsh interface show interface
echo.
echo ═══════════════════════════════════════════════════════════════
echo Detalhes completos:
echo.
ipconfig /all
call :PauseMenu
goto :MENU

:TESTE_CONECTIVIDADE
call :PrintHeader
echo.
echo ╔═════════════════════════════════════════════════════════════╗
echo ║        TESTE DE CONECTIVIDADE INTERNET                      ║
echo ╚═════════════════════════════════════════════════════════════╝
echo.
echo Testando 8.8.8.8 (Google DNS)...
ping -n 6 8.8.8.8
echo.
echo Testando 1.1.1.1 (Cloudflare DNS)...
ping -n 6 1.1.1.1
echo.
echo Testando google.com (Resolução de nomes)...
ping -n 6 google.com
echo.
echo ✅ Testes concluídos!
call :PauseMenu
goto :MENU

:: ---------------------[ Segurança e Sistema ]---------------------

:PONTO_RESTAURACAO
call :PrintHeader
if not "%_IS_ADMIN%"=="1" (
    echo.
    echo ⚠️  Esta funcao requer privilegios de Administrador!
    call :PauseMenu
    goto :MENU
)

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║          CRIAR PONTO DE RESTAURAÇÃO                           ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo Criando ponto de restauração manual...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Checkpoint-Computer -Description 'SuporteTI_Manual_%date:~0,2%%date:~3,2%%date:~6,4%' -RestorePointType 'MODIFY_SETTINGS'"
echo.
echo ✅ Ponto de restauração criado!
echo ℹ️  (Se a Proteção do Sistema estiver ativa)
call :PauseMenu
goto :MENU

:FIREWALL_OFF
call :PrintHeader
if not "%_IS_ADMIN%"=="1" (
    echo.
    echo ⚠️  Esta funcao requer privilegios de Administrador!
    call :PauseMenu
    goto :MENU
)

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║             DESATIVAR FIREWALL DO WINDOWS                     ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo ⚠️  ATENÇÃO: Desligar o firewall REDUZ A SEGURANÇA do sistema!
echo ⚠️  Use apenas para diagnóstico temporário!
echo.
call :ConfirmAction "Deseja REALMENTE desativar o Firewall"
if /I not "%_CONFIRM%"=="Y" goto :MENU

:: Criar backup do estado do firewall
call :CreateBackup FIREWALL

echo.
netsh advfirewall set allprofiles state off
echo.
echo ✅ Firewall desativado em todos os perfis.
echo ℹ️  Use a opção [15] para reativar.
call :PauseMenu
goto :MENU

:FIREWALL_ON
call :PrintHeader
if not "%_IS_ADMIN%"=="1" (
    echo.
    echo ⚠️  Esta funcao requer privilegios de Administrador!
    call :PauseMenu
    goto :MENU
)

echo.
echo Ativando Firewall do Windows...
netsh advfirewall set allprofiles state on
echo.
echo ✅ Firewall ativado em todos os perfis!
call :PauseMenu
goto :MENU

:LOGS_EVENTOS
call :PrintHeader
echo.
echo Abrindo Visualizador de Eventos...
start "" eventvwr.msc
echo.
echo ✅ Visualizador de Eventos aberto!
call :PauseMenu
goto :MENU

:VERIFICAR_UPDATES
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║        VERIFICAR ATUALIZAÇÕES DO WINDOWS                      ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo Abrindo Windows Update...
start ms-settings:windowsupdate
echo.
echo ✅ Janela de atualizações aberta!
call :PauseMenu
goto :MENU

:: ---------------------[ Utilitários Avançados ]---------------------

:CMD_ADMIN
call :PrintHeader
echo.
echo Abrindo Prompt de Comando como Administrador...
powershell -NoProfile -Command "Start-Process cmd -Verb RunAs"
echo.
echo ℹ️  Aprove o UAC quando solicitado.
call :PauseMenu
goto :MENU

:TASK_MANAGER
call :PrintHeader
echo.
echo Abrindo Gerenciador de Tarefas...
start "" taskmgr
echo.
echo ✅ Gerenciador de Tarefas aberto!
call :PauseMenu
goto :MENU

:WINGET_UPDATE
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║        ATUALIZAR PACOTES COM WINGET                           ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

where winget >nul 2>&1
if errorlevel 1 (
    echo ❌ winget não encontrado neste sistema.
    echo ℹ️  O winget está disponível no Windows 11 e Windows 10 (com App Installer).
    call :PauseMenu
    goto :MENU
)

echo Listando atualizações disponíveis...
winget upgrade

echo.
call :ConfirmAction "Deseja atualizar TODOS os pacotes"
if /I not "%_CONFIRM%"=="Y" goto :MENU

echo.
echo Atualizando pacotes...
winget upgrade --all --include-unknown

echo.
echo ✅ Atualização concluída!
call :PauseMenu
goto :MENU

:GPUPDATE
call :PrintHeader
echo.
echo Forçando atualização de políticas de grupo...
gpupdate /force
echo.
echo ✅ Atualização de políticas concluída!
call :PauseMenu
goto :MENU

:LISTAR_APPS
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║        APLICATIVOS NATIVOS DO WINDOWS INSTALADOS              ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
powershell -NoProfile -Command "$i=1; Get-AppxPackage | ForEach-Object { [PSCustomObject]@{Index=$i; Name=$_.Name}; $i++ } | Format-Table -AutoSize"
call :PauseMenu
goto :MENU

:REMOVER_APP
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║        REMOVER APLICATIVO NATIVO DO WINDOWS                   ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo ⚠️  ATENÇÃO: Será criado um backup antes de remover.
echo.

:: Criar backup da lista de apps instalados
call :CreateBackup APPS

echo.
echo Listando aplicativos instalados...
echo.

set "PS_SCRIPT=%TEMP%\RemoveApps_%RANDOM%.ps1"
echo $i=1 > "%PS_SCRIPT%"
echo $apps = Get-AppxPackage ^| Select-Object Name, PackageFullName >> "%PS_SCRIPT%"
echo if ($apps.Count -eq 0) { Write-Host 'Nenhum aplicativo encontrado.' -ForegroundColor Yellow; exit 1 } >> "%PS_SCRIPT%"
echo $appsEnum = $apps ^| ForEach-Object { [PSCustomObject]@{Index=$i; Name=$_.Name; PackageFullName=$_.PackageFullName}; $i++ } >> "%PS_SCRIPT%"
echo $appsEnum ^| Format-Table Index, Name -AutoSize >> "%PS_SCRIPT%"
echo Write-Host '' >> "%PS_SCRIPT%"
echo $input = Read-Host 'Digite o numero do aplicativo a remover (0 para cancelar)' >> "%PS_SCRIPT%"
echo $index = [int]$input >> "%PS_SCRIPT%"
echo if ($index -eq 0) { Write-Host 'Cancelado.' -ForegroundColor Yellow; exit 0 } >> "%PS_SCRIPT%"
echo if ($index -gt 0 -and $index -le $appsEnum.Count) { >> "%PS_SCRIPT%"
echo     $target = $appsEnum[$index-1] >> "%PS_SCRIPT%"
echo     Write-Host "Removendo: $($target.Name)" -ForegroundColor Yellow >> "%PS_SCRIPT%"
echo     try { >> "%PS_SCRIPT%"
echo         Remove-AppxPackage -Package $target.PackageFullName -ErrorAction Stop >> "%PS_SCRIPT%"
echo         Write-Host 'Aplicativo removido com sucesso!' -ForegroundColor Green >> "%PS_SCRIPT%"
echo     } catch { >> "%PS_SCRIPT%"
echo         Write-Host "ERRO ao remover: $($_.Exception.Message)" -ForegroundColor Red >> "%PS_SCRIPT%"
echo     } >> "%PS_SCRIPT%"
echo } else { >> "%PS_SCRIPT%"
echo     Write-Host 'Numero invalido!' -ForegroundColor Red >> "%PS_SCRIPT%"
echo } >> "%PS_SCRIPT%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
del "%PS_SCRIPT%" >nul 2>&1

if errorlevel 1 (
    echo.
    echo ⚠️  Não foi possível listar ou remover aplicativos.
)

echo.
call :PauseMenu
goto :MENU

:LOG_WUPDATE
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║        GERAR LOG DO WINDOWS UPDATE                            ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo Gerando WindowsUpdate.log na Área de Trabalho...
echo ℹ️  Este processo pode demorar alguns minutos...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-WindowsUpdateLog -LogPath \"$env:USERPROFILE\Desktop\WindowsUpdate.log\""

echo.
echo ✅ Log gerado com sucesso!
echo 📄 Arquivo: %USERPROFILE%\Desktop\WindowsUpdate.log
call :PauseMenu
goto :MENU

:FERRAMENTAS_SISTEMA
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║             FERRAMENTAS DO SISTEMA                            ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo  [1] Gerenciamento do Computador (compmgmt.msc)
echo  [2] Gerenciador de Dispositivos (devmgmt.msc)
echo  [3] Serviços (services.msc)
echo  [4] Editor de Registro (regedit) ⚠️
echo  [5] Informações do Sistema (msinfo32)
echo  [6] Monitor de Recursos (resmon)
echo  [7] Monitor de Desempenho (perfmon)
echo  [8] Limpeza de Disco (cleanmgr)
echo  [9] Desfragmentador (dfrgui)
echo  [0] Voltar ao Menu Principal
echo.
set "TOOL="
set /p "TOOL=Escolha uma ferramenta: "

if "%TOOL%"=="1" start "" compmgmt.msc
if "%TOOL%"=="2" start "" devmgmt.msc
if "%TOOL%"=="3" start "" services.msc
if "%TOOL%"=="4" start "" regedit
if "%TOOL%"=="5" start "" msinfo32
if "%TOOL%"=="6" start "" resmon
if "%TOOL%"=="7" start "" perfmon
if "%TOOL%"=="8" start "" cleanmgr
if "%TOOL%"=="9" start "" dfrgui
if "%TOOL%"=="0" goto :MENU

echo.
echo ✅ Ferramenta aberta!
call :PauseMenu
goto :MENU

:: ---------------------[ Relatórios e Info ]---------------------

:INFO_SISTEMA
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║        INFORMAÇÕES COMPLETAS DO SISTEMA                       ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
systeminfo
echo.
call :PauseMenu
goto :MENU

:RELATORIO_HARDWARE
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║            RELATÓRIO DE HARDWARE                              ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

echo 🖥️  PROCESSADOR:
wmic cpu get name,numberofcores,numberoflogicalprocessors,maxclockspeed /format:list

echo.
echo 💾 MEMÓRIA RAM:
wmic memorychip get capacity,manufacturer,speed /format:list

echo.
echo 💽 DISCOS:
wmic diskdrive get model,size,interfacetype /format:list

echo.
echo 🎴 PLACA DE VÍDEO:
wmic path win32_videocontroller get name,driverversion,videomodedescription /format:list

echo.
call :PauseMenu
goto :MENU

:SAUDE_BATERIA
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║          VERIFICAR SAÚDE DA BATERIA (LAPTOPS)                 ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

set "BATTERY_REPORT=%~dp0logs\battery-report_%YY%%MM%%DD%.html"

echo Gerando relatório de bateria...
powercfg /batteryreport /output "%BATTERY_REPORT%"

if errorlevel 1 (
    echo.
    echo ❌ Não foi possível gerar o relatório.
    echo ℹ️  Este computador pode não ter bateria (desktop).
) else (
    echo.
    echo ✅ Relatório gerado com sucesso!
    echo 📄 Arquivo: %BATTERY_REPORT%
    echo.
    call :ConfirmAction "Deseja abrir o relatório no navegador"
    if /I "%_CONFIRM%"=="Y" start "" "%BATTERY_REPORT%"
)

call :PauseMenu
goto :MENU

:PROGRAMAS_INSTALADOS
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║          PROGRAMAS INSTALADOS NO SISTEMA                      ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
wmic product get name,version,vendor /format:table
echo.
echo ℹ️  Nota: Esta lista pode não incluir todos os programas.
call :PauseMenu
goto :MENU

:: ---------------------[ Backup e Restauração ]---------------------

:MENU_LIST_BACKUPS
call :ListBackups
call :PauseMenu
goto :MENU

:MENU_RESTORE_BACKUP
call :RestoreBackup
goto :MENU

:LIMPAR_BACKUPS
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║              LIMPAR BACKUPS ANTIGOS                           ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

if not exist "%~dp0backups\backup_*.txt" (
    echo ⚠️  Nenhum backup encontrado para limpar.
    call :PauseMenu
    goto :MENU
)

echo Esta opção irá remover backups com mais de 30 dias.
echo.
call :ConfirmAction "Deseja continuar"
if /I not "%_CONFIRM%"=="Y" goto :MENU

echo.
echo Procurando backups antigos...

set "BACKUP_REMOVED=0"
forfiles /P "%~dp0backups" /M backup_*.txt /D -30 /C "cmd /c del @path && echo Removido: @file && set /a BACKUP_REMOVED+=1" 2>nul

if errorlevel 1 (
    echo.
    echo ℹ️  Nenhum backup com mais de 30 dias encontrado.
) else (
    echo.
    echo ✅ Backups antigos removidos!
)

call :PauseMenu
goto :MENU

:: ---------------------[ Interface Gráfica ]---------------------

:START_GUI
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║            INICIANDO INTERFACE GRÁFICA (GUI)                  ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo Iniciando SuporTI_GUI.ps1...
echo.

set "GUI_SCRIPT=%~dp0SuporTI_GUI.ps1"

if not exist "%GUI_SCRIPT%" (
    echo ❌ ERRO: Arquivo SuporTI_GUI.ps1 não encontrado!
    echo.
    call :PauseMenu
    goto :MENU
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%GUI_SCRIPT%"

echo.
echo ✅ Interface gráfica encerrada.
call :PauseMenu
goto :MENU

:: ---------------------[ Finalização ]---------------------

:SAIR
call :PrintHeader
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                  ENCERRANDO FERRAMENTA                        ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
call :LogEcho "Ferramenta encerrada pelo usuario"
echo  Obrigado por usar a Ferramenta de Suporte TI!
echo  Log salvo em: %LOGFILE%
echo.
echo  Até logo! 👋
echo.
timeout /t 3
endlocal
exit /b 0
