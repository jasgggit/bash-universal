# Bash Universal v1.4.2 — Bash + Fastfetch

## Sistemas
- Linux: Ubuntu 20.04/22.04/24.04, Debian e Rocky Linux 9; executar como root.
- macOS: **apenas contas cuja shell de login seja Bash** (`dscl`/`SHELL`). Executar **sem sudo**. Se for Zsh, o instalador não modifica nada.
- O instalador não altera Zsh, PAM, SSH, systemd-getty, autologin ou configurações de Fastfetch existentes.

## Instalação
Rever primeiro o código e testar num servidor não crítico:

```bash
curl -fsSL https://raw.githubusercontent.com/jasgggit/bash-universal/main/install.sh -o /tmp/bash-universal.sh
bash -n /tmp/bash-universal.sh
# Linux: sudo bash /tmp/bash-universal.sh
# macOS Bash: bash /tmp/bash-universal.sh
```

Após publicação no GitHub, o comando de uma linha continua disponível:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/jasgggit/bash-universal/main/install.sh)"
```

## Bash
- Prompt Kali de duas linhas: root vermelho, outros utilizadores verde-claro, hostname ciano, moldura azul/lilás.
- Histórico: mínimos 50 000/100 000, `histappend`, `history -a`; não apaga históricos.
- Aliases `ls`, `ll`, `la`, `l`; GNU `--color=auto` no Linux e BSD `-G` no macOS.
- Linux: configuração em `/etc/profile.d/99-jgomes-bash.sh`, com hooks geridos em `.bashrc` existentes e `/etc/skel`.
- macOS: configuração no `~/.config/jgomes-bash/config.sh`, hooks em `~/.bashrc` e `~/.bash_profile` da conta atual.

## Fastfetch
- Linux: preserva instalações existentes; tenta instalar com `apt`/`dnf` **apenas se o pacote existir nos repositórios já configurados**. Se não estiver disponível, mostra um MOTD mínimo. Não adiciona repositórios nem descarrega binários arbitrários.
- Linux com `/etc/update-motd.d`: cria apenas `05-jgomes-fastfetch`; a apresentação depende do PAM/MOTD da distribuição. Rocky pode não executar scripts deste diretório; não é forçada integração PAM.
- macOS Bash: se faltar Fastfetch e existir Homebrew, tenta `brew install fastfetch`. Mostra-o em sessões de login Bash interativas, uma vez por árvore de sessão. Se não existir Homebrew, mantém o Bash configurado sem Fastfetch.
- O instalador não ativa autologin de root nos LXCs. As secções de autologin do documento de origem são deliberadamente excluídas.

## Estado e remoção

```bash
bash install.sh --status
bash install.sh --uninstall
```

A remoção retira os hooks geridos e a configuração Bash/MOTD gerida. **Não desinstala Fastfetch**, não elimina históricos e mantém os backups. No macOS, não modifica Zsh.

## Limitações e precauções
- macOS utiliza Bash 3.2 de sistema, que exige tratamento diferente do Bash 5.x Linux.
- A deteção de Bash no macOS verifica a shell de login da conta; iniciar `bash` manualmente a partir de uma conta Zsh não autoriza mudanças persistentes.
- O fallback Fastfetch no Linux é intencionalmente conservador: sistemas sem pacote nos repositórios não recebem um binário externo. A instalação por releases oficiais, com verificação de arquitetura, dependências e checksums, pode ser acrescentada numa versão posterior.
- Antes de instalar em servidores com histórico extenso, encerrar sessões antigas com cuidado; uma sessão antiga com limites baixos pode truncar o histórico quando termina.
- No Linux, scripts preexistentes de MOTD podem apresentar informação adicional ou duplicada; o instalador não os elimina automaticamente.
- **Estado:** sintaxe verificada; testes funcionais reais em macOS, Ubuntu, Debian e Rocky ainda pendentes.

## v1.4.2 — Evitar Fastfetch duplicado

Antes de criar o MOTD, deteta scripts executáveis existentes em `/etc/update-motd.d/` que invoquem `fastfetch`. Preserva scripts e configurações personalizados (por exemplo `/etc/update-motd.d/00-fastfetch` e `/etc/fastfetch/server.json`). Se existir integração externa, remove apenas o script reconhecido como gerido pela v1.4.0, se presente. Não remove integrações de terceiros na desinstalação. No macOS Bash verifica integrações Fastfetch nos ficheiros de login antes de acrescentar uma nova.

**Limitações:** a deteção é estática; invocações indiretas por scripts auxiliares podem não ser detetadas. A instalação e execução efetivas do Fastfetch dependem dos repositórios e do mecanismo de login do sistema. Testar primeiro num servidor piloto.

## v1.4.2

Corrigida a inicialização de `motd_dir` sob `set -u` na função `setup_fastfetch`. Não altera as regras de deteção de integrações Fastfetch existentes.
