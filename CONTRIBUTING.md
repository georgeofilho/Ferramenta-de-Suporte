# Contribuindo para o Ferramenta de Suporte

Obrigado pelo seu interesse em contribuir para o **Ferramenta de Suporte**! 🎉

Este documento fornece diretrizes e passos para ajudá-lo a contribuir com o projeto de forma eficaz.

## Como posso contribuir?

### 🐛 Reportando Bugs

Se você encontrou um erro, por favor abra uma **Issue** no GitHub com:
1.  **Título claro** descrevendo o problema.
2.  **Passos para reproduzir** (ex: "Cliquei na aba Rede > Bota Flush DNS e apareceu o erro X").
3.  **Captura de tela** ou o texto do erro no log.
4.  Versão do seu Windows.

### 💡 Sugerindo Melhorias

Tem uma ideia de nova funcionalidade? Abra uma **Issue** com a tag `enhancement` (melhoria) explicando:
*   Qual o problema que essa funcionalidade resolve?
*   Como você imagina que ela deveria funcionar na interface?

### 💻 Enviando Código (Pull Requests)

1.  **Faça um Fork** do repositório.
2.  Crie uma branch para sua modificação:
    ```bash
    git checkout -b feature/minha-nova-funcionalidade
    ```
3.  **Mantenha o padrão de código**:
    *   Use `Write-Log` para todas as saídas de texto.
    *   Evite acentos nos arquivos de código para garantir compatibilidade.
    *   Use `FlowLayoutPanel` para adicionar botões novos (não use coordenadas fixas X,Y).
4.  Commit suas alterações com mensagens claras.
5.  Envie para o seu fork e abra um **Pull Request**.

## Estrutura do Projeto

*   `Ferramenta de Suporte_GUI.ps1`: O script principal da interface gráfica.
*   `backups/`: Diretório onde backups de configuração são salvos.
*   `logs/`: Diretório onde os logs de execução são salvos.

## Regras de Conduta

*   Seja respeitoso e colaborativo.
*   Críticas construtivas são bem-vindas.
*   O foco é criar uma ferramenta útil para todos os técnicos.

Obrigado por ajudar a tornar o Ferramenta de Suporte melhor! 🚀
