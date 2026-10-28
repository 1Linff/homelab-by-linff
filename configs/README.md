# Configurações de exemplo

Arquivos de referência usados na documentação. **Todos os IPs são fictícios** e portas, chaves e senhas estão como `<MARCADORES>`.

| Arquivo | Uso | Explicado em |
|---|---|---|
| `mikrotik/firewall.rsc` | Interface lists, firewall e serviços da MikroTik | [docs/03](../docs/03-hardening-mikrotik.md) |
| `mikrotik/wireguard.rsc` | Cliente WireGuard na MikroTik | [docs/02](../docs/02-wireguard-cgnat.md) |
| `servidor/wg0.conf.example` | Hub WireGuard no Ubuntu | [docs/02](../docs/02-wireguard-cgnat.md) |
| `servidor/99-hardening.conf` | Hardening do SSH | [docs/04](../docs/04-hardening-servidor.md) |
| `servidor/jail.local` | Fail2ban | [docs/04](../docs/04-hardening-servidor.md) |
| `servidor/99-sysctl-hardening.conf` | Ajustes de kernel | [docs/04](../docs/04-hardening-servidor.md) |
