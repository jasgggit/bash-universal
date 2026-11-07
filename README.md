# JGomes Bash Universal

Instalador para Bash interativo em Ubuntu, Debian e Rocky Linux. Mantém os prompts personalizados (incluindo Kali), preserva os históricos existentes, define limites mínimos de 50 000/100 000 comandos, `histappend`, gravação incremental com `history -a`, cores ciano para diretórios e aliases `ls`, `ll`, `la`, `l`.

## Instalação a partir do GitHub

Publicar `install.sh` na raiz de um repositório público, por exemplo `jasgggit/bash-universal` (nome ilustrativo; confirmar antes de executar).

```bash
curl -fsSLo /tmp/jgomes-bash-install.sh https://raw.githubusercontent.com/UTILIZADOR/REPOSITORIO/main/install.sh
less /tmp/jgomes-bash-install.sh
sudo bash /tmp/jgomes-bash-install.sh --install
```

Depois de verificar o conteúdo e o endereço, também é possível executar diretamente:

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/UTILIZADOR/REPOSITORIO/main/install.sh)"
```

## Operações

```bash
sudo bash install.sh --status
sudo bash install.sh --uninstall
```

A instalação é idempotente. São guardadas cópias dos `.bashrc` e `.bash_history` existentes em `/var/lib/jgomes-bash/backup-*`. O script não limpa nem reescreve os históricos originais. A desinstalação remove apenas os blocos geridos e o ficheiro de configuração, não restaura automaticamente outras personalizações anteriores.

**Limitações:** aplica-se a utilizadores com Bash como shell de login e `.bashrc` existente (root ou UID >= 1000); novos utilizadores precisam de voltar a executar o instalador. Não modifica o Bash do macOS. Uma definição posterior de `PROMPT_COMMAND` ou `LS_COLORS`, ou hooks de prompt autorreferenciais, podem sobrepor esta configuração; verificar sempre numa nova sessão. Sessões SSH já abertas podem manter valores antigos e devem ser encerradas cuidadosamente. Os backups podem ocupar espaço se os históricos forem grandes.
