# 04 · Hardening do servidor na nuvem

Servidor **Ubuntu** na **Oracle Cloud**, com IP público e exposto à internet 24 horas por dia. Logo depois de criado, ele já começa a receber tentativas de login automatizadas. O hardening segue a regra de **expor o mínimo possível**.

## Duas camadas de firewall

| Camada | Onde | Regra |
|---|---|---|
| 1 | **Security List** da Oracle Cloud (antes de chegar no servidor) | Libera só `<PORTA_SSH>/tcp` e `<PORTA_WG>/udp` |
| 2 | **UFW** no próprio Ubuntu | Default deny + as mesmas duas exceções |

Se uma camada for mal configurada, a outra continua protegendo.

## 1. SSH só por chave

Arquivo `/etc/ssh/sshd_config.d/99-hardening.conf`:
```
Port <PORTA_SSH>
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
```

| Diretiva | O que faz |
|---|---|
| `Port` | Tira o SSH da porta 22. Não é proteção real, mas elimina boa parte do ruído de bots |
| `PermitRootLogin no` | Ninguém entra direto como root; uso usuário comum + `sudo` |
| `PasswordAuthentication no` | **Senha desativada**: só entra quem tem a chave privada. Força bruta deixa de fazer sentido |
| `KbdInteractiveAuthentication no` | Fecha outra forma de autenticação por senha |
| `MaxAuthTries 3` | Limita tentativas por conexão |

Chave gerada no cliente com:
```bash
ssh-keygen -t ed25519 -C "notebook-linff"
```
| Parte | Tipo | O que faz |
|---|---|---|
| `-t ed25519` | opção com valor | Algoritmo da chave (moderno, curto e seguro) |
| `-C "..."` | opção com valor | Comentário para identificar de onde é a chave |

> ⚠️ Antes de reiniciar o SSH, testar o login por chave **numa segunda sessão aberta**, para não ficar trancado para fora.
> No Ubuntu recente o SSH é ativado por socket: depois de mudar a porta, rodar `sudo systemctl daemon-reload && sudo systemctl restart ssh.socket`.

## 2. Firewall default deny (UFW)
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow <PORTA_SSH>/tcp
sudo ufw allow <PORTA_WG>/udp
sudo ufw enable
```

| Parte | O que faz |
|---|---|
| `default deny incoming` | Bloqueia toda conexão de entrada por padrão |
| `default allow outgoing` | O servidor pode iniciar conexões (updates, DNS) |
| `allow <PORTA>/<proto>` | Exceções explícitas: só SSH e WireGuard |
| `enable` | Ativa o firewall e o mantém após reboot |

## 3. Fail2ban

Bane temporariamente IPs que erram o login várias vezes. Arquivo `/etc/fail2ban/jail.local`:
```ini
[sshd]
enabled  = true
port     = <PORTA_SSH>
maxretry = 5
findtime = 10m
bantime  = 1h
```

| Parâmetro | O que faz |
|---|---|
| `maxretry` | Quantas falhas são toleradas |
| `findtime` | Janela de tempo em que as falhas são contadas |
| `bantime` | Quanto tempo o IP fica bloqueado |

Conferir os banidos: `sudo fail2ban-client status sshd`.

## 4. Ajustes de kernel (sysctl)

Arquivo `/etc/sysctl.d/99-hardening.conf`:
```
net.ipv4.ip_forward = 1                    # necessário: o servidor é o hub da VPN
net.ipv4.conf.all.rp_filter = 1            # descarta pacotes com IP de origem falsificado
net.ipv4.conf.all.accept_redirects = 0     # ignora ICMP redirect (evita desvio de rota)
net.ipv4.conf.all.send_redirects = 0
net.ipv4.tcp_syncookies = 1                # proteção contra SYN flood
```
Aplicar sem reiniciar: `sudo sysctl --system`.

## 5. Rotina
- `sudo apt update && sudo apt upgrade` com frequência (ou `unattended-upgrades` para patches de segurança).
- Revisar `sudo ss -tulpn`: **toda** porta escutando precisa ter um motivo.
- Revisar `journalctl -u ssh` e o status do Fail2ban.

## Resultado
| Antes | Depois |
|---|---|
| SSH na 22, com senha e root | SSH em porta própria, só chave, sem root |
| Qualquer porta acessível se um serviço subisse | Default deny em duas camadas |
| Força bruta ilimitada | Fail2ban bane IPs automaticamente |
