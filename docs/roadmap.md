# 🗺️ Roadmap

O lab está em evolução constante. Próximos passos:

## Redes
- [ ] **Bridge VLAN filtering** na MikroTik (trunk de verdade, VLANs separadas para IoT e laboratório)
- [ ] VLAN de laboratório com uma VM Linux isolada
- [ ] Roteamento estático e failover de link

## Observabilidade
- [ ] **Syslog remoto:** MikroTik enviando logs para um servidor Linux (rsyslog)
- [ ] **SNMP + Zabbix ou Grafana** para monitorar a MikroTik

## Segurança
- [ ] **Firewall sob teste:** escanear a MikroTik a partir de um Kali e conferir os contadores de cada regra
- [ ] Lab ofensivo isolado: Kali × alvo vulnerável em rede interna do VirtualBox
- [ ] Auditoria do servidor com `lynis` e CIS Benchmarks

## Automação (o "Dev" do DevSecOps)
- [ ] Script Bash de **backup automático** da MikroTik via SSH com `/export hide-sensitive`
- [ ] Scripts e scheduler do RouterOS
- [ ] Configuração do servidor como código (Ansible)

## Infraestrutura
- [ ] **Proxmox** em hardware dedicado: VMs, containers e backup
- [ ] Docker/Compose para serviços do lab
