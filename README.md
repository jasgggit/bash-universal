# JGomes Bash Universal v1.3.0

Configuração de Bash interativo para Debian, Ubuntu e Rocky Linux: prompt Kali de duas linhas, root vermelho, utilizadores normais verde-claro, hostname ciano, diretórios ciano, aliases `ls`, `ll`, `la`, `l`, e histórico com mínimos de 50 000/100 000 comandos.

## Instalação

Como root, após rever o código publicado:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/jasgggit/bash-universal/main/install.sh)"
```

Para testar antes da instalação, descarregar e inspecionar `install.sh`, executar `bash -n install.sh` e depois `sudo bash install.sh`.

## Como funciona

- Configuração em `/etc/profile.d/99-jgomes-bash.sh`.
- Integração no `/etc/bash.bashrc` (Debian/Ubuntu) ou `/etc/bashrc` (Rocky), e no final dos `.bashrc` de utilizadores Bash existentes e de `/etc/skel/.bashrc` para novas contas.
- Os `.bashrc` dos utilizadores continuam a ser executados; a configuração gerida é aplicada no fim.
- Reinstalações não duplicam blocos identificados pelos marcadores `JGOMES BASH MANAGED`.
- Faz backups dos `.bashrc` alterados e dos `.bash_history` existentes em `/var/lib/jgomes-bash/backup-*` (sem modificar os históricos originais).
- Não reduz limites superiores já existentes na sessão, nem apaga ou reescreve históricos.

## Validação

Abrir **nova sessão SSH** e executar:

```bash
echo "$HISTSIZE $HISTFILESIZE"
shopt histappend
declare -p PROMPT_COMMAND
alias ll
ll /opt
```

Testar também `su - utilizador` ou `sudo -i` quando aplicável.

## Estado e remoção

```bash
bash install.sh --status
bash install.sh --uninstall
```

A remoção retira apenas os blocos geridos e o ficheiro central; não restaura outras personalizações preexistentes e não altera históricos.

## Limitações e cuidados

- Só Bash interativo, não Zsh nem macOS.
- Utilizadores existentes sem `.bashrc` ou com inicialização especial podem exigir ajuste manual.
- O Bash não garante execução de um hook global *depois* de todos os ficheiros pessoais sem acrescentar um hook ao `.bashrc` individual.
- Instalações antigas personalizadas, como o AISYS, podem ter `/etc/profile.d/99-shell-custom.sh` e linhas anteriores em `/etc/bash.bashrc`; o instalador **avisa mas não apaga** essas alterações. Rever e consolidar separadamente depois do teste.
- Sessões abertas podem manter limites antigos e truncar o histórico ao sair; efetuar migração em janela controlada.
- Executar scripts remotos via `curl | bash` implica confiar no conteúdo atual do branch. Para ambientes críticos, fixar uma tag/commit e rever o script.
