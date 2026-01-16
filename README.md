# 🛠️ Ferramenta de Suporte Técnico (v2.0)

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)
![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-blue)
![License](https://img.shields.io/badge/License-MIT-green)

O **Ferramenta de Suporte** é uma ferramenta "tudo-em-um" desenvolvida em PowerShell com interface gráfica (GUI), projetada para facilitar a vida de técnicos de informática e usuários avançados. Ela centraliza diagnósticos, reparações, configurações de rede e segurança em um único painel moderno e intuitivo.

---

## 🚀 Funcionalidades Principais

A ferramenta é dividida em 6 módulos principais:

### 1. 💻 Diagnóstico e Sistema
*   **Limpeza Completa:** Remove arquivos temporários, prefetch e executa o *Disk Cleanup*.
*   **Reparo de Sistema:** Automação de `SFC /Scannow` e `DISM` para corrigir arquivos corrompidos do Windows.
*   **Otimização:** Desfragmentação e otimização de disco (TRIM para SSDs).
*   **Relatórios:** Gera arquivos de texto detalhados com informações de hardware e sistema.

### 2. 🌐 Rede e Conectividade
*   **Diagnóstico de Internet:** Testes de Ping automáticos (Google/Cloudflare) para verificar latência.
*   **Reset de Rede:** Reinicia a pilha TCP/IP, Winsock e Firewall em caso de problemas graves de conexão (inclui reinicialização automática).
*   **Ferramentas:** Flush DNS, visualização de IP detalhado, teste de velocidade (Speedtest web) e lista de adaptadores.

### 3. 🔒 Segurança
*   **Firewall:** Botões rápidos para Ativar ou Desativar o Firewall do Windows.
*   **Ponto de Restauração:** Criação de pontos de restauração do sistema com um clique.
*   **Updates:** Atalho direto para verificar atualizações do Windows.
*   **Logs:** Acesso rápido ao Visualizador de Eventos.

### 4. 🛠️ Utilitários
*   **CMD Admin:** Abre o Prompt de Comando com privilégios elevados.
*   **Winget:** Interface para atualizar todos os programas instalados via Winget.
*   **Apps Nativos:** Listagem e remoção (Debloat) de aplicativos nativos do Windows 10/11.
*   **Atalhos MSC:** Acesso rápido ao Regedit, Serviços e Gerenciador de Dispositivos.

### 5. 📊 Relatórios Detalhados
*   **Hardware:** Detalhes de Processador, Memória RAM (Slots/Frequência) e Discos.
*   **Bateria:** Gera e abre o relatório oficial de saúde da bateria do Windows (`battery-report`).
*   **Programas:** Lista todo o software instalado no sistema.

### 6. 💾 Backups
*   **Gerenciamento:** Lista backups de configurações gerados pela ferramenta.
*   **Limpeza:** Remove backups antigos para economizar espaço.

---

## 📥 Instalação e Uso

### Pré-requisitos
*   Windows 10 ou Windows 11.
*   PowerShell 5.1 (Padrão no Windows) ou superior.
*   Privilégios de **Administrador** são necessários para a maioria das funções.

### Como Executar

1.  Baixe o arquivo `Ferramenta de Suporte_GUI.ps1` (ou clone este repositório).
2.  Clique com o botão direito no arquivo e selecione **"Executar com o PowerShell"**.

> **Nota:** Se o script fechar imediatamente ou não abrir, pode ser necessário liberar a execução de scripts no seu PC.

**Para liberar a execução (apenas na primeira vez):**
Abra o PowerShell como Administrador e digite:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```
*(Isso libera a execução apenas para a sessão atual, mantendo seu sistema seguro)*.

---

## ⚠️ Isenção de Responsabilidade (Disclaimer)

Esta ferramenta executa comandos administrativos poderosos (como resetar rede, modificar firewall, remover apps).
*   **Use com cuidado.**
*   A função **"Resetar Rede"** irá reiniciar seu computador. Salve seus trabalhos antes de usar.
*   Sempre crie um **Ponto de Restauração** (disponível na aba Segurança) antes de realizar grandes alterações.

---

## 🤝 Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir Issues ou enviar Pull Requests com melhorias, correções de bugs ou novas funcionalidades.

1.  Faça um Fork do projeto.
2.  Crie uma Branch para sua Feature (`git checkout -b feature/NovaFuncionalidade`).
3.  Commit suas mudanças (`git commit -m 'Adiciona Nova Funcionalidade'`).
4.  Push para a Branch (`git push origin feature/NovaFuncionalidade`).
5.  Abra um Pull Request.

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

By George Filho
