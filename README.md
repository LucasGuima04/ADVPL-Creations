# 🚀 ADVPL-Creations

<p align="center">
  <strong>Desenvolvimento ADVPL para TOTVS Protheus</strong>
  <br />
  Fontes, projetos, rotinas e soluções para desenvolvimento e aprendizado no ecossistema TOTVS.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Language-ADVPL-blue?style=for-the-badge" alt="Linguagem ADVPL" />
  <img src="https://img.shields.io/badge/ERP-TOTVS%20Protheus-orange?style=for-the-badge" alt="TOTVS Protheus" />
  <img src="https://img.shields.io/badge/Editor-VS%20Code-007ACC?style=for-the-badge&logo=visualstudiocode&logoColor=white" alt="Visual Studio Code" />
  <img src="https://img.shields.io/badge/Version%20Control-Git-F05032?style=for-the-badge&logo=git&logoColor=white" alt="Git" />
</p>

---

## 📌 Sobre o projeto

O **ADVPL-Creations** é um repositório dedicado ao desenvolvimento de fontes e soluções utilizando **ADVPL (Advanced Protheus Language)**, linguagem utilizada no ecossistema TOTVS Protheus.

O objetivo é centralizar códigos, experimentos, projetos e implementações desenvolvidos durante o aprendizado e a prática de programação para o ERP, mantendo um histórico organizado das alterações por meio do Git e do GitHub.

Este repositório também funciona como um ambiente de evolução técnica, permitindo documentar soluções, aprimorar boas práticas de programação e construir um portfólio de desenvolvimento voltado ao Protheus.

## 🎯 Objetivos

- Desenvolver e armazenar fontes ADVPL de maneira organizada.
- Praticar lógica de programação aplicada ao ERP TOTVS Protheus.
- Explorar rotinas, funções e recursos da linguagem.
- Desenvolver soluções para necessidades específicas de sistemas empresariais.
- Aprimorar a manutenção, a legibilidade e a reutilização de código.
- Utilizar Git e GitHub para versionamento e documentação dos projetos.
- Construir um portfólio técnico de desenvolvimento ADVPL.

## 🛠️ Tecnologias e ferramentas

| Tecnologia | Finalidade |
|---|---|
| **ADVPL** | Desenvolvimento de fontes e rotinas para o Protheus. |
| **TOTVS Protheus** | Ambiente ERP de execução das soluções. |
| **Visual Studio Code** | Edição e organização dos fontes. |
| **Extensão TOTVS para VS Code** | Apoio ao desenvolvimento e à compilação, conforme a configuração do ambiente. |
| **Git** | Controle de versão do código-fonte. |
| **GitHub** | Hospedagem, histórico e compartilhamento dos projetos. |

> **Observação:** a compilação e a execução dos fontes dependem de um ambiente Protheus devidamente configurado, com acesso autorizado aos serviços necessários.

## 📂 Estrutura do repositório

A organização atual inclui as seguintes pastas e arquivos:

```text
ADVPL-Creations/
├── .github/
│   └── instructions/
├── .vscode/
├── MyProjects/
└── README.md
```

### Descrição dos diretórios

- **`MyProjects/`** — diretório destinado aos projetos e fontes desenvolvidos em ADVPL.
- **`.vscode/`** — configurações relacionadas ao ambiente de desenvolvimento no Visual Studio Code.
- **`.github/instructions/`** — instruções e orientações utilizadas no contexto do repositório e do desenvolvimento.
- **`README.md`** — documentação principal do projeto.

A estrutura poderá evoluir conforme novos fontes, módulos e projetos forem adicionados.

## 💻 Ambiente de desenvolvimento

O ambiente de desenvolvimento pode ser configurado utilizando o Visual Studio Code integrado às ferramentas de desenvolvimento TOTVS.

### Pré-requisitos

Antes de trabalhar com os fontes, recomenda-se possuir:

- [Visual Studio Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/)
- Extensão TOTVS para desenvolvimento ADVPL.
- Acesso a um ambiente TOTVS Protheus de desenvolvimento.
- Permissões necessárias para acessar e compilar os fontes no ambiente configurado.

Os requisitos específicos podem variar de acordo com a versão do Protheus e a infraestrutura utilizada.

## ⚙️ Como clonar o repositório

Para obter uma cópia local do projeto, abra o terminal e execute:

```bash
git clone https://github.com/LucasGuima04/ADVPL-Creations.git
```

Entre na pasta criada:

```bash
cd ADVPL-Creations
```

Abra o projeto no Visual Studio Code:

```bash
code .
```

Caso o comando `code` não esteja disponível no terminal, abra o Visual Studio Code e selecione a pasta do projeto manualmente.

## 🧩 Desenvolvimento e compilação

Os fontes ADVPL podem ser editados no Visual Studio Code utilizando a extensão TOTVS e as configurações correspondentes ao ambiente de desenvolvimento.

### Fluxo recomendado

1. Abra o repositório no Visual Studio Code.
2. Acesse a pasta `MyProjects/`.
3. Abra ou crie o fonte desejado, utilizando a extensão `.PRW` para fontes ADVPL quando apropriado.
4. Implemente a lógica e revise o código.
5. Utilize os recursos de compilação disponibilizados pela extensão e pela configuração do ambiente TOTVS.
6. Analise eventuais mensagens de erro e corrija os problemas encontrados.
7. Teste a rotina em um ambiente de desenvolvimento ou homologação antes de utilizá-la em produção.

> **Importante:** salvar um arquivo `.PRW` não significa que ele foi compilado no Protheus. A compilação precisa ser realizada pelo mecanismo configurado no ambiente TOTVS.

## 🌿 Versionamento com Git

O Git é utilizado para registrar a evolução dos fontes e facilitar o acompanhamento das alterações.

### Verificar alterações

```bash
git status
```

### Adicionar arquivos modificados

```bash
git add .
```

### Registrar um commit

```bash
git commit -m "Descrição das alterações"
```

### Enviar alterações para o GitHub

```bash
git push
```

### Atualizar a cópia local

```bash
git pull
```

### Exemplo de fluxo completo

```bash
git add .
git commit -m "Adiciona nova rotina ADVPL"
git push
```

Sempre revise os arquivos incluídos antes de executar `git add .`, especialmente para evitar o envio de arquivos de configuração local, credenciais ou informações confidenciais.

## 📐 Boas práticas de desenvolvimento

Para manter o repositório organizado e facilitar a manutenção dos fontes, recomenda-se:

- Utilizar nomes claros e consistentes para funções, variáveis e arquivos.
- Documentar regras de negócio que não sejam evidentes no código.
- Manter cada alteração relacionada a um objetivo específico.
- Evitar duplicação desnecessária de código.
- Validar parâmetros e tratar situações de erro.
- Seguir os padrões de nomenclatura e as convenções adotadas no ambiente Protheus.
- Testar as alterações antes de disponibilizá-las para uso.
- Registrar commits com mensagens que expliquem o propósito da mudança.
- Não versionar senhas, tokens, certificados, dados pessoais ou informações internas da empresa.

## 🧪 Testes e validação

Os testes devem ser realizados de acordo com a finalidade de cada fonte e com as particularidades do ambiente em que será executado.

Sempre que aplicável, recomenda-se verificar:

- Compilação sem erros.
- Comportamento esperado da rotina.
- Tratamento de entradas inválidas e situações excepcionais.
- Compatibilidade com as regras de negócio envolvidas.
- Impactos sobre processos e rotinas existentes.
- Resultados em ambiente de desenvolvimento ou homologação.

O procedimento de teste deve considerar as dependências e os recursos utilizados por cada implementação.

## 🤝 Contribuições

Sugestões, melhorias e novas implementações podem contribuir para a evolução do repositório.

Para propor uma alteração:

1. Faça um fork do projeto ou crie uma branch específica.
2. Implemente a alteração desejada.
3. Revise o código e valide o comportamento.
4. Registre as mudanças com um commit descritivo.
5. Envie suas alterações para o GitHub.
6. Abra um Pull Request com uma explicação objetiva da implementação.

Sugestões de mensagens para commits:

```text
feat: adiciona nova funcionalidade
fix: corrige comportamento de uma rotina
refactor: melhora a organização do código
docs: atualiza a documentação
test: adiciona validações
```

Esses prefixos são convenções sugeridas para tornar o histórico mais fácil de compreender.

## 🔒 Segurança e uso responsável

Os fontes devem ser utilizados respeitando as permissões de acesso, as licenças aplicáveis e as políticas do ambiente em que foram desenvolvidos.

Antes de publicar qualquer implementação, verifique se ela contém:

- Credenciais ou dados de conexão.
- Informações confidenciais da empresa.
- Dados reais de clientes ou fornecedores.
- Regras de negócio restritas.
- Código de terceiros sem autorização de redistribuição.

**Nunca publique informações confidenciais ou fontes corporativos sem a autorização necessária.**

## 📚 Referências úteis

- [Documentação oficial do GitHub](https://docs.github.com/)
- [Documentação do Git](https://git-scm.com/doc)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Portal TOTVS](https://www.totvs.com/)
- [Central de Atendimento e documentação TOTVS](https://centraldeatendimento.totvs.com/)

Consulte sempre a documentação compatível com a versão do Protheus utilizada no ambiente de desenvolvimento.

## 👨‍💻 Autor

**Lucas Guimarães**

Desenvolvimento de soluções em ADVPL para TOTVS Protheus, com foco em aprendizado contínuo, organização de código e evolução técnica.

- **GitHub:** [@LucasGuima04](https://github.com/LucasGuima04)
- **Repositório:** [ADVPL-Creations](https://github.com/LucasGuima04/ADVPL-Creations)

---

<p align="center">
  Desenvolvido com dedicação ao aprendizado e à evolução no ecossistema TOTVS Protheus. 💻
</p>

