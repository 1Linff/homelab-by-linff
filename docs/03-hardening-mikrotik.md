# 03 · Hardening da MikroTik

Objetivo: a MikroTik deve **rotear e proteger a rede**, e não ficar exposta. A configuração segue três ideias: firewall *default deny*, serviços mínimos e gerência só por caminhos conhecidos.

> Antes de mexer em firewall ou serviços: **Safe Mode** ligado (`Ctrl+X` no terminal ou botão *Safe Mode* no WinBox). Se a conexão cair, as mudanças são desfeitas automaticamente.

## 1. Interface lists

**Terminal RouterOS**
```routeros
/interface list add name=WAN
/interface list add name=LAN
/interface list add name=MGMT
/interface list member add list=WAN  interface=ether1
/interface list member add list=LAN  interface=bridge-lan
/interface list member add list=LAN  interface=vlan-wifi
/interface list member add list=MGMT interface=ether5
/interface list member add list=MGMT interface=wg-cloud
```
**WinBox:** *Interfaces* → aba **Interface List** → botão **Lists** (criar as listas) → `+` para adicionar cada membro.

## 2. Firewall

A ordem importa: o RouterOS avalia as regras de cima para baixo e para na primeira que casar.

**Terminal RouterOS**
```routeros
/ip firewall filter
# --- tráfego para o próprio roteador (input) ---
add chain=input action=accept connection-state=established,related,untracked comment="aceita respostas"
add chain=input action=drop   connection-state=invalid comment="descarta pacotes invalidos"
add chain=input action=accept protocol=icmp comment="ping e diagnostico"
add chain=input action=accept in-interface-list=MGMT comment="gerencia so pela porta dedicada e pela VPN"
add chain=input action=accept in-interface-list=LAN protocol=udp dst-port=53 comment="DNS para a rede interna"
add chain=input action=drop comment="default deny"
# --- tráfego que atravessa o roteador (forward) ---
add chain=forward action=accept connection-state=established,related,untracked comment="aceita respostas"
add chain=forward action=drop   connection-state=invalid comment="descarta pacotes invalidos"
add chain=forward action=drop   connection-state=new connection-nat-state=!dstnat in-interface-list=WAN comment="nada da WAN entra sem port forward"
```

| Parte | O que faz |
|---|---|
| `chain=input` | Pacotes destinados à **própria** MikroTik |
| `chain=forward` | Pacotes que **atravessam** a MikroTik (LAN ↔ internet) |
| `connection-state=established,related` | Respostas de conexões que já foram aceitas |
| `connection-state=invalid` | Pacotes que não pertencem a nenhuma conexão válida |
| `in-interface-list=MGMT` | Só vale para o que entra pelas interfaces da lista de gerência |
| `connection-nat-state=!dstnat` | Conexões novas vindas da WAN que **não** passaram por port forward |
| `action=drop` (sem filtro) | Última regra: tudo o que não foi liberado acima é descartado |

**WinBox:** *IP* → *Firewall* → aba **Filter Rules** → `+`. Abas **General** (chain, protocol, port, in. interface list), **Advanced** (connection state, NAT state) e **Action**. Depois, arrastar as regras para a ordem acima.

## 3. Serviços mínimos

**Terminal RouterOS**
```routeros
/ip service disable telnet,ftp,www,www-ssl,api,api-ssl
/ip service set winbox address=192.168.99.0/24,10.200.0.0/24
/ip service set ssh    address=192.168.99.0/24,10.200.0.0/24
/ip proxy set enabled=no
/ip socks set enabled=no
```

| Parte | O que faz |
|---|---|
| `/ip service disable ...` | Desliga serviços de gerência que não uso (Telnet e FTP não têm criptografia) |
| `set winbox address=...` | WinBox só aceita conexões vindas da rede de gerência e da VPN |
| `/ip proxy` / `/ip socks` | Proxies desligados: não devem existir num roteador doméstico |

**WinBox:** *IP* → *Services* → desabilitar (✕) os serviços não usados → duplo clique em *winbox* e *ssh* → campo **Available From**.

## 4. Camada 2: MAC-WinBox e descoberta de vizinhos

Por padrão, a MikroTik aceita login por endereço MAC e se anuncia (MNDP/CDP/LLDP) em todas as portas.

**Terminal RouterOS**
```routeros
/tool mac-server set allowed-interface-list=MGMT
/tool mac-server mac-winbox set allowed-interface-list=MGMT
/ip neighbor discovery-settings set discover-interface-list=MGMT
```
**WinBox:** *Tools* → *MAC Server* (botões **MAC Telnet Server** e **MAC WinBox Server**) → *Allowed Interface List* = `MGMT`; *IP* → *Neighbors* → **Discovery Settings** → *Interface* = `MGMT`.

## 5. Usuários
```routeros
/user add name=<SEU_USUARIO> group=full password=<SENHA_FORTE>
/user disable admin
```
O usuário `admin` é o primeiro alvo de qualquer tentativa de força bruta. Criei um usuário próprio e desativei o padrão.
**WinBox:** *System* → *Users* → `+`; depois selecionar `admin` → ✕ (disable).

## 6. Manutenção
- **RouterOS atualizado** (*System* → *Packages* → *Check For Updates*) e depois **firmware** (*System* → *RouterBOARD* → *Upgrade*).
- **NTP client** ativo, para os logs terem horário confiável:
  ```routeros
  /system ntp client set enabled=yes servers=a.ntp.br,b.ntp.br
  ```
- **Port forwards revisados:** regras antigas sem uso são removidas.
- **Backup seguro:** `/export hide-sensitive file=config` gera um texto sem chaves e senhas.

## Resultado
- Nenhuma porta de gerência visível da internet nem do Wi-Fi.
- Toda a administração passa pela porta dedicada ou pela VPN.
- Configuração legível, com comentários em cada regra.
