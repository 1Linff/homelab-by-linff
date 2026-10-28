# Exemplo - IPs ficticios. Aplicar com Safe Mode ligado.
/interface list
add name=WAN
add name=LAN
add name=MGMT
/interface list member
add list=WAN  interface=ether1
add list=LAN  interface=bridge-lan
add list=LAN  interface=vlan-wifi
add list=MGMT interface=ether5
add list=MGMT interface=wg-cloud

/ip firewall filter
add chain=input action=accept connection-state=established,related,untracked comment="aceita respostas"
add chain=input action=drop connection-state=invalid comment="descarta pacotes invalidos"
add chain=input action=accept protocol=icmp comment="ping e diagnostico"
add chain=input action=accept in-interface-list=MGMT comment="gerencia so pela porta dedicada e pela VPN"
add chain=input action=accept in-interface-list=LAN protocol=udp dst-port=53 comment="DNS para a rede interna"
add chain=input action=drop comment="default deny"
add chain=forward action=accept connection-state=established,related,untracked comment="aceita respostas"
add chain=forward action=drop connection-state=invalid comment="descarta pacotes invalidos"
add chain=forward action=drop connection-state=new connection-nat-state=!dstnat in-interface-list=WAN comment="nada da WAN entra sem port forward"

/ip service
disable telnet,ftp,www,www-ssl,api,api-ssl
set winbox address=192.168.99.0/24,10.200.0.0/24
set ssh address=192.168.99.0/24,10.200.0.0/24

/tool mac-server set allowed-interface-list=MGMT
/tool mac-server mac-winbox set allowed-interface-list=MGMT
/ip neighbor discovery-settings set discover-interface-list=MGMT
/ip proxy set enabled=no
/ip socks set enabled=no
/system ntp client set enabled=yes servers=a.ntp.br,b.ntp.br
