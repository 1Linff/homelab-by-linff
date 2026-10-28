# 02 · WireGuard contornando o CGNAT

## O problema

Com **CGNAT**, o provedor coloca vários clientes atrás de um mesmo IP público. Minha MikroTik recebe um IP privado do provedor, então **nenhuma conexão vinda de fora consegue chegar até ela**. Port forwarding não resolve, porque a porta precisaria ser aberta no equipamento do provedor.

## A ideia

Se ninguém consegue entrar, **todo mundo sai**. Um servidor na nuvem tem IP público. Os equipamentos de casa iniciam a conexão até ele, e o servidor vira o ponto de encontro: a topologia **hub-and-spoke**.

```
          ┌────────────────────────┐
          │  Servidor Oracle Cloud │  ← hub (IP público)
          │      10.200.0.1        │
          └───────▲────────▲───────┘
     túnel UDP    │        │   túnel UDP
     (saída)      │        │   (saída)
        ┌─────────┴──┐  ┌──┴──────────┐
        │  MikroTik  │  │  Notebook   │  ← spokes (atrás de CGNAT)
        │ 10.200.0.2 │  │ 10.200.0.3  │
        └────────────┘  └─────────────┘
```

### Por que WireGuard
- Código pequeno e criptografia moderna (Curve25519, ChaCha20-Poly1305).
- Usa só **UDP**, uma porta, e é suportado nativamente no RouterOS 7 e no kernel Linux.
- Autenticação por par de chaves, como no SSH.

### O detalhe que faz funcionar: `persistent-keepalive`
O CGNAT esquece mapeamentos UDP inativos depois de algum tempo. Se o túnel ficar quieto, o servidor perde o caminho de volta. Com `persistent-keepalive = 25`, cada spoke manda um pacote a cada 25 s e mantém o mapeamento vivo.

## Configuração (exemplo)

### Servidor (hub) · `/etc/wireguard/wg0.conf`
```ini
[Interface]
Address    = 10.200.0.1/24
ListenPort = <PORTA_WG>
PrivateKey = <CHAVE_PRIVADA_DO_SERVIDOR>   # nunca versionar

[Peer]
# MikroTik
PublicKey  = <CHAVE_PUBLICA_MIKROTIK>
AllowedIPs = 10.200.0.2/32

[Peer]
# Notebook
PublicKey  = <CHAVE_PUBLICA_NOTEBOOK>
AllowedIPs = 10.200.0.3/32
```

| Parte | O que faz |
|---|---|
| `Address` | IP do servidor dentro do túnel |
| `ListenPort` | Porta UDP onde o servidor escuta (liberada no firewall e na security list da nuvem) |
| `PrivateKey` | Chave privada do servidor; fica só nele |
| `[Peer]` | Cada cliente autorizado |
| `AllowedIPs` | IP que aquele peer pode usar no túnel; `/32` = exatamente um endereço |

Para o hub repassar tráfego entre os spokes, o encaminhamento IP fica ativo: `net.ipv4.ip_forward = 1` (ver [04](04-hardening-servidor.md)).

Subir e habilitar no boot:
```bash
sudo systemctl enable --now wg-quick@wg0
```

| Parte | O que faz |
|---|---|
| `systemctl` | Gerencia serviços do systemd |
| `enable` | Faz o serviço iniciar junto com o sistema |
| `--now` | Flag: além de habilitar, já inicia agora |
| `wg-quick@wg0` | Serviço do WireGuard usando o arquivo `wg0.conf` |

### MikroTik (spoke)

**Terminal RouterOS**
```routeros
/interface wireguard add name=wg-cloud listen-port=<PORTA_LOCAL>
/interface wireguard peers add interface=wg-cloud \
    public-key="<CHAVE_PUBLICA_DO_SERVIDOR>" \
    endpoint-address=<IP_PUBLICO_DO_SERVIDOR> endpoint-port=<PORTA_WG> \
    allowed-address=10.200.0.0/24 persistent-keepalive=25s
/ip address add address=10.200.0.2/24 interface=wg-cloud
```

| Parte | O que faz |
|---|---|
| `/interface wireguard add` | Cria a interface WireGuard; a chave privada é gerada automaticamente |
| `public-key` | Chave pública do servidor (identifica o hub) |
| `endpoint-address` / `endpoint-port` | Onde o hub está na internet |
| `allowed-address=10.200.0.0/24` | Toda a rede do túnel passa por esse peer, incluindo os outros spokes |
| `persistent-keepalive=25s` | Mantém o mapeamento do CGNAT ativo |
| `/ip address add` | IP da MikroTik dentro do túnel |

**WinBox:** *WireGuard* → aba **WireGuard** → `+` (nome `wg-cloud`) → aba **Peers** → `+` (interface, public key, endpoint, allowed address, keepalive) → *IP* → *Addresses* → `+`.

### Notebook (spoke) · `/etc/wireguard/wg0.conf`
```ini
[Interface]
Address    = 10.200.0.3/24
PrivateKey = <CHAVE_PRIVADA_DO_NOTEBOOK>

[Peer]
PublicKey           = <CHAVE_PUBLICA_DO_SERVIDOR>
Endpoint            = <IP_PUBLICO_DO_SERVIDOR>:<PORTA_WG>
AllowedIPs          = 10.200.0.0/24
PersistentKeepalive = 25
```

## Verificação
```bash
sudo wg show
```
O campo `latest handshake` mostra há quanto tempo cada peer falou com o servidor. Se ele estiver sempre abaixo de 2 minutos, o túnel está saudável.

## Boas práticas aplicadas
- Chaves privadas nunca saem do equipamento onde foram geradas.
- Cada peer tem um `/32` próprio: um cliente não consegue se passar por outro.
- Backup da MikroTik por `/export hide-sensitive`, que **não** inclui chaves privadas.
