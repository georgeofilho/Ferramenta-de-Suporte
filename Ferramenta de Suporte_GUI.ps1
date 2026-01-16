Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# --- Configuracoes de UI ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "SuporTI - Ferramenta de Suporte v2.0 (GUI Completa)"
$form.Size = New-Object System.Drawing.Size(1000, 700)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.ForeColor = [System.Drawing.Color]::White

# --- Funcao de Log ---
function Write-Log {
    param([string]$Message)
    $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $Message`r`n")
    $txtOutput.ScrollToCaret()
}

# --- Helper: Tabs ---
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Dock = "Top"
$tabControl.Height = 450
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Controls.Add($tabControl)

function New-Tab {
    param($Title)
    $tab = New-Object System.Windows.Forms.TabPage $Title
    $tab.BackColor = [System.Drawing.Color]::White
    $tab.AutoScroll = $true
    
    # Layout Panel para organizar botoes automaticamente
    $panel = New-Object System.Windows.Forms.FlowLayoutPanel
    $panel.Dock = "Fill"
    $panel.FlowDirection = "LeftToRight"
    $panel.WrapContents = $true
    $panel.AutoScroll = $true
    $panel.Padding = New-Object System.Windows.Forms.Padding(10)
    $tab.Controls.Add($panel)
    
    $tabControl.TabPages.Add($tab)
    return $panel
}

# --- Helper: Botoes ---
function Add-Button {
    param($ParentPanel, $Text, $Action, $Color = [System.Drawing.Color]::FromArgb(0, 122, 204))
    
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Size = New-Object System.Drawing.Size(220, 60)
    $btn.Margin = New-Object System.Windows.Forms.Padding(5)
    $btn.BackColor = $Color
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.FlatStyle = "Flat"
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btn.Add_Click($Action)
    
    $ParentPanel.Controls.Add($btn)
}

function Create-Section-Label {
    param($ParentPanel, $Text)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "--- $Text ---"
    $lbl.AutoSize = $false
    $lbl.Size = New-Object System.Drawing.Size(900, 30)
    $lbl.TextAlign = "MiddleCenter"
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lbl.Margin = New-Object System.Windows.Forms.Padding(0, 20, 0, 10)
    $ParentPanel.Controls.Add($lbl)
    $ParentPanel.SetFlowBreak($lbl, $true) # Quebra linha apos o label
}

# ==============================================================================
#                      CRIACAO DAS ABAS E BOTOES
# ==============================================================================

# --- ABA 1: DIAGNOSTICO ---
$pnlDiag = New-Tab "Diagnostico"

Add-Button $pnlDiag "Limpeza Completa" {
    Write-Log "Iniciando Limpeza Completa..."
    Write-Log "Limpando pasta TEMP..."
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Limpando Prefetch..."
    Start-Process "powershell" -ArgumentList "-Command Remove-Item -Path 'C:\Windows\Prefetch\*' -Recurse -Force" -Verb RunAs -Wait
    Write-Log "Executando Limpeza de Disco (Cleanmgr)..."
    Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:65535"
    Write-Log "Limpeza concluida!"
}
Add-Button $pnlDiag "Reparo Sistema (SFC/DISM)" {
    $conf = [Microsoft.VisualBasic.Interaction]::MsgBox("Isso pode demorar. Continuar?", "YesNo,SystemModal,Question", "Confirmar")
    if ($conf -eq "Yes") {
        Write-Log "Iniciando DISM ScanHealth..."
        Start-Process "dism" -ArgumentList "/Online /Cleanup-Image /ScanHealth" -Verb RunAs -Wait
        Write-Log "Iniciando DISM RestoreHealth..."
        Start-Process "dism" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Verb RunAs -Wait
        Write-Log "Iniciando SFC Scannow..."
        Start-Process "sfc" -ArgumentList "/scannow" -Verb RunAs -Wait
        Write-Log "Reparos concluidos."
    }
}
Add-Button $pnlDiag "Otimizar Disco C:" {
    Write-Log "Otimizando Disco C..."
    Start-Process "defrag" -ArgumentList "C: /O /U /V" -Verb RunAs -ResultSize 0
}
Add-Button $pnlDiag "Teste Desempenho Disco" {
    Write-Log "Executando Winsat Disk..."
    Start-Process "winsat" -ArgumentList "disk" -Verb RunAs -Wait
    Write-Log "Teste finalizado."
}
Add-Button $pnlDiag "Relatorio do Sistema" {
    Write-Log "Gerando relatorio..."
    $file = "$env:USERPROFILE\Desktop\Relatorio_Sistema.txt"
    Get-ComputerInfo | Out-File $file
    Start-Process "notepad" $file
    Write-Log "Relatorio salvo na Area de Trabalho."
}

# --- ABA 2: REDE ---
$pnlRede = New-Tab "Rede"

Add-Button $pnlRede "Diagnostico Internet" {
    Write-Log "Pingando Google (8.8.8.8)..."
    Test-Connection 8.8.8.8 -Count 4 | Out-String | ForEach-Object { Write-Log $_ }
    Write-Log "Pingando Cloudflare (1.1.1.1)..."
    Test-Connection 1.1.1.1 -Count 4 | Out-String | ForEach-Object { Write-Log $_ }
}
Add-Button $pnlRede "Resetar Rede (Completo)" {
    $conf = [Microsoft.VisualBasic.Interaction]::MsgBox("Resetar TODAS as configs de rede e reiniciar?", "YesNo,SystemModal,Exclamation", "Perigo")
    if ($conf -eq "Yes") {
        Write-Log "Resetando Winsock/IP/Firewall..."
        Start-Process "netsh" -ArgumentList "winsock reset" -Verb RunAs -Wait
        Start-Process "netsh" -ArgumentList "int ip reset" -Verb RunAs -Wait
        Start-Process "netsh" -ArgumentList "advfirewall reset" -Verb RunAs -Wait
        Write-Log "Reiniciando em 10 segundos..."
        Start-Process "shutdown" -ArgumentList "/r /t 10"
    }
} "Red"

Add-Button $pnlRede "Flush DNS" {
    Invoke-Expression "ipconfig /flushdns"
    Write-Log "Cache DNS limpo."
}
Add-Button $pnlRede "Ver IP (Detalhado)" {
    Start-Process "cmd" -ArgumentList "/k ipconfig /all"
}
Add-Button $pnlRede "Speedtest (Web)" {
    Start-Process "https://www.speedtest.net"
}
Add-Button $pnlRede "Adaptadores de Rede" {
    Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed | Out-String | ForEach-Object { Write-Log $_ }
}

# --- ABA 3: SEGURANCA ---
$pnlSec = New-Tab "Seguranca"

Add-Button $pnlSec "Criar Ponto Restauracao" {
    Write-Log "Criando Ponto de Restauracao..."
    Checkpoint-Computer -Description "Manual_SuporTI_GUI" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    if ($?) { Write-Log "Sucesso!" } else { Write-Log "Erro (Precisa ser Admin ou Protecao desativada)" }
}
Add-Button $pnlSec "Desativar Firewall" {
    Start-Process "netsh" -ArgumentList "advfirewall set allprofiles state off" -Verb RunAs
    Write-Log "Firewall Desativado (Cuidado!)"
} "DarkRed"

Add-Button $pnlSec "Ativar Firewall" {
    Start-Process "netsh" -ArgumentList "advfirewall set allprofiles state on" -Verb RunAs
    Write-Log "Firewall Ativado."
} "Green"

Add-Button $pnlSec "Logs de Eventos" {
    Start-Process "eventvwr"
}
Add-Button $pnlSec "Windows Update" {
    Start-Process "ms-settings:windowsupdate"
}

# --- ABA 4: UTILITARIOS ---
$pnlUtil = New-Tab "Utilitarios"

Add-Button $pnlUtil "CMD (Admin)" { Start-Process "cmd" -Verb RunAs }
Add-Button $pnlUtil "Gerenciador Tarefas" { Start-Process "taskmgr" }
Add-Button $pnlUtil "Winget Update All" { 
    Start-Process "cmd" -ArgumentList "/k winget upgrade --all" 
}
Add-Button $pnlUtil "GPUpdate Force" { 
    Start-Process "cmd" -ArgumentList "/k gpupdate /force" 
}
Add-Button $pnlUtil "Listar Apps Nativos" {
    Get-AppxPackage | Select-Object Name, PackageFullName | Out-GridView -Title "Apps Instalados"
}
Add-Button $pnlUtil "Remover App Nativo" {
    $app = [Microsoft.VisualBasic.Interaction]::InputBox("Digite parte do nome do App:", "Remover App")
    if ($app) {
        Get-AppxPackage | Where-Object { $_.Name -like "*$app*" } | Remove-AppxPackage -ErrorAction SilentlyContinue -Verbose
        Write-Log "Tentativa de remocao de *$app* concluida."
    }
}
Add-Button $pnlUtil "Log Windows Update" {
    Get-WindowsUpdateLog -LogPath "$env:USERPROFILE\Desktop\WindowsUpdate.log" -ErrorAction SilentlyContinue
    Write-Log "Log salvo no Desktop."
}

# Sub-secao Ferramentas MSC
Create-Section-Label $pnlUtil "Atalhos do Sistema"

Add-Button $pnlUtil "Gerenc. Dispositivos" { Start-Process "devmgmt.msc" } "Gray"
Add-Button $pnlUtil "Servicos" { Start-Process "services.msc" } "Gray"
Add-Button $pnlUtil "Regedit" { Start-Process "regedit" } "Gray"
Add-Button $pnlUtil "Painel Controle" { Start-Process "control" } "Gray"

# --- ABA 5: RELATORIOS ---
$pnlRel = New-Tab "Relatorios"

Add-Button $pnlRel "Info Completa (SystemInfo)" {
    Start-Process "cmd" -ArgumentList "/k systeminfo"
}
Add-Button $pnlRel "Relatorio Hardware" {
    Write-Log "--- PROCESSADOR ---"
    Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores | Out-String | ForEach-Object { Write-Log $_ }
    Write-Log "--- MEMORIA ---"
    Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | ForEach-Object { Write-Log "Total RAM: $([math]::round($_.Sum / 1GB, 2)) GB" }
    Write-Log "--- DISCO ---"
    Get-CimInstance Win32_DiskDrive | Select-Object Model, @{N = "Size(GB)"; E = { [math]::round($_.Size / 1GB, 2) } } | Out-String | ForEach-Object { Write-Log $_ }
}
Add-Button $pnlRel "Saude Bateria" {
    Start-Process "powercfg" -ArgumentList "/batteryreport /output $env:USERPROFILE\Desktop\bateria.html"
    Write-Log "Relatorio salvo no Desktop (bateria.html)"
    Start-Process "$env:USERPROFILE\Desktop\bateria.html"
}
Add-Button $pnlRel "Programas Instalados" {
    Get-WmiObject -Class Win32_Product | Select-Object Name, Version | Out-GridView -Title "Programas Instalados"
}

# --- ABA 6: BACKUPS ---
$pnlBkp = New-Tab "Backups"

Add-Button $pnlBkp "Listar Backups" {
    $path = "$PSScriptRoot\backups"
    if (Test-Path $path) {
        Get-ChildItem $path | Select-Object Name, Length, LastWriteTime | Out-GridView -Title "Backups Disponiveis"
    }
    else {
        Write-Log "Nenhum backup encontrado ou pasta inexistente."
    }
}
Add-Button $pnlBkp "Limpar Backups Antigos" {
    $days = 30
    $path = "$PSScriptRoot\backups"
    if (Test-Path $path) {
        Get-ChildItem $path | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$days) } | Remove-Item -Verbose
        Write-Log "Limpeza executada (arquivos > $days dias)."
    }
}

# ==============================================================================
#                      AREA DE LOG E INICIALIZACAO
# ==============================================================================

$grpLog = New-Object System.Windows.Forms.GroupBox
$grpLog.Text = "Log de Operacoes"
$grpLog.Dock = "Bottom"
$grpLog.Height = 200
$grpLog.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($grpLog)

$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Multiline = $true
$txtOutput.ScrollBars = "Vertical"
$txtOutput.Dock = "Fill"
$txtOutput.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$txtOutput.ForeColor = [System.Drawing.Color]::LimeGreen
$txtOutput.Font = New-Object System.Drawing.Font("Consolas", 10)
$txtOutput.ReadOnly = $true
$grpLog.Controls.Add($txtOutput)

Write-Log "GUI Carregada com Sucesso."
Write-Log "SuporTI v3.0 - Selecione uma aba e uma funcao."

$form.ShowDialog()
