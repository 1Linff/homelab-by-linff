# 🧪 Homelab by Linff

Laboratório pessoal onde eu coloco em prática **redes, segurança e infraestrutura**, os três pilares do caminho que estou seguindo rumo a **DevSecOps**.

Não é um ambiente simulado: é a rede real da minha casa, com um roteador MikroTik, um servidor Linux na nuvem e estações de análise, tudo configurado, protegido e documentado por mim.

![Topologia do homelab](assets/topologia.png)

---

## 🎯 O problema que deu origem ao lab

Minha conexão residencial fica atrás de **CGNAT**: não tenho IP público, então nada de fora consegue iniciar uma conexão com a minha rede. Isso impede acesso remoto e serviços hospedados em casa.

A solução foi montar uma **VPN WireGuard em topologia hub-and-spoke**, com um servidor na **Oracle Cloud** como ponto central. A partir disso o lab cresceu para hardening, firewall e análise de tráfego.

## 🧩 Componentes

| Componente | Papel no lab |
|---|---|
| **MikroTik RB850Gx2** (RouterOS 7) | Roteador principal: firewall, NAT, DHCP, VLAN e cliente da VPN |
| **Servidor Ubuntu na Oracle Cloud** | Hub da VPN WireGuard, com hardening completo |
| **Notebook com Linux Mint** | Estação de análise de rede (Wireshark, tcpdump, nmap) e cliente da VPN |
| **PC com Windows 11** | Estação de administração; WSL 2 (Kali, Ubuntu, AlmaLinux) e VirtualBox para labs isolados |

## 📚 Documentação

| # | Tema | O que tem lá |
|---|---|---|
| 01 | [Topologia](docs/01-topologia.md) | Segmentação da rede e função de cada parte |
| 02 | [WireGuard e CGNAT](docs/02-wireguard-cgnat.md) | Como o túnel contorna o CGNAT, passo a passo |
| 03 | [Hardening da MikroTik](docs/03-hardening-mikrotik.md) | Firewall, serviços, gerência restrita |
| 04 | [Hardening do servidor na nuvem](docs/04-hardening-servidor.md) | SSH, firewall default deny, Fail2ban, sysctl |
| 05 | [Análise de tráfego](docs/05-analise-de-trafego.md) | Captura remota com TZSP + Wireshark, inventário com nmap |
| — | [Roadmap](docs/roadmap.md) | Próximos passos do lab |

Exemplos de configuração estão em [`configs/`](configs/).

## 🛠️ Tecnologias

`MikroTik RouterOS` · `WireGuard` · `Ubuntu Server` · `Oracle Cloud` · `UFW` · `Fail2ban` · `Wireshark` · `tcpdump` · `nmap` · `Linux Mint` · `WSL 2` · `VirtualBox`

## 🔐 Sobre segurança desta documentação

Este repositório é público, então **nenhum dado real da minha rede está aqui**:

- endereços IP são exemplos (`192.168.x.0/24`, `10.200.0.0/24`);
- portas de serviços expostos aparecem como `<PORTA_SSH>`, `<PORTA_WG>`;
- chaves e senhas aparecem como `<CHAVE_PUBLICA_...>`, e chaves privadas nunca são versionadas;
- configurações da MikroTik são exportadas com `/export hide-sensitive`, nunca por arquivo `.backup` (que carrega as chaves).

## 💡 O que este lab me ensinou

- **Pensar em camadas:** um problema de acesso remoto envolve NAT (camada 3), UDP (camada 4) e criptografia ao mesmo tempo.
- **Default deny:** começar bloqueando tudo e liberar só o necessário é mais simples de auditar do que o contrário.
- **Reduzir superfície de ataque:** serviço que não é usado fica desligado; gerência só por caminhos conhecidos.
- **Documentar é parte do trabalho:** cada mudança aqui tem o porquê registrado, não só o comando.

---

👤 **Arthur Pacher Santos**: estagiário de TI (suporte e infraestrutura) e estudante de Engenharia de Software na UniCesumar.
[LinkedIn](https://www.linkedin.com/in/arthur-pacher) · [GitHub](https://github.com/1Linff)
