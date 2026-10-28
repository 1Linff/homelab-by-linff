# 05 · Análise de tráfego

Ter firewall não basta: é preciso **ver** o que circula na rede. O notebook com Linux Mint funciona como estação de análise.

## Captura remota: MikroTik → Wireshark (TZSP)

A MikroTik copia os pacotes de uma interface e os envia, encapsulados em **TZSP** (UDP), para o notebook. O Wireshark decodifica o TZSP nativamente e mostra os pacotes originais, como se o notebook estivesse plugado naquela porta.

**Terminal RouterOS**
```routeros
/tool sniffer set streaming-enabled=yes streaming-server=192.168.20.50 \
    filter-interface=ether1 filter-stream=yes
/tool sniffer start
# ... captura ...
/tool sniffer stop
```

| Parte | O que faz |
|---|---|
| `streaming-enabled=yes` | Envia os pacotes pela rede em vez de gravar em arquivo |
| `streaming-server=` | IP da estação de análise (exemplo) |
| `filter-interface=` | Qual interface observar |
| `filter-stream=yes` | Não captura o próprio fluxo TZSP (evita loop) |

**WinBox:** *Tools* → *Packet Sniffer* → aba **Streaming** (marcar *Streaming Enabled*, *Server*, *Filter Stream*) → aba **Filter** (interface) → **Start**.

**No notebook (Wireshark):** capturar na interface de rede com o filtro `udp port 37008`, a porta padrão do TZSP.

## Inventário da rede com nmap

Descobrir quem está na rede e comparar com os leases do DHCP da MikroTik. Dispositivo que aparece no scan mas não está na lista é motivo para investigar.

```bash
sudo nmap -sn 192.168.20.0/24
```
| Parte | Tipo | O que faz |
|---|---|---|
| `-sn` | flag | *Ping scan*: só descobre hosts ativos, sem varrer portas |
| `192.168.20.0/24` | argumento posicional | Rede alvo (exemplo) |

Conferir serviços de um host específico **da própria rede**:
```bash
sudo nmap -sS -sV -p- --min-rate 1000 192.168.10.20
```
| Parte | Tipo | O que faz |
|---|---|---|
| `-sS` | flag | SYN scan (meia conexão, mais rápido e discreto) |
| `-sV` | flag | Detecta a versão do serviço em cada porta aberta |
| `-p-` | flag | Todas as 65.535 portas |
| `--min-rate 1000` | opção com valor | Envia pelo menos 1.000 pacotes por segundo |

## Captura em linha de comando (tcpdump)
```bash
sudo tcpdump -i wlan0 -w captura.pcap
```
| Parte | Tipo | O que faz |
|---|---|---|
| `-i wlan0` | opção com valor | Interface a capturar |
| `-w captura.pcap` | opção com valor | Grava em arquivo para abrir depois no Wireshark |

## Casos reais investigados com essas ferramentas
- **Inventário de dispositivos:** cruzamento do `nmap -sn` com os leases do DHCP para identificar cada equipamento e fixar IPs.
- **Atribuição de tráfego:** identificar qual processo do Windows gerava conexões, combinando DNS/TLS-SNI no Wireshark com as conexões ativas no sistema.
- **IP em blacklist:** investigação do tráfego de saída e bloqueio de SMTP de saída na MikroTik com address list.

> ⚖️ Scans e capturas são feitos **somente na minha própria rede**. Escanear redes de terceiros sem autorização é ilegal.
