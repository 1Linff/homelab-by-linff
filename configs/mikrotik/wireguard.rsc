# Exemplo - substituir os <MARCADORES>. A chave privada e gerada automaticamente.
/interface wireguard add name=wg-cloud listen-port=<PORTA_LOCAL>
/interface wireguard peers add interface=wg-cloud public-key="<CHAVE_PUBLICA_DO_SERVIDOR>" \
    endpoint-address=<IP_PUBLICO_DO_SERVIDOR> endpoint-port=<PORTA_WG> \
    allowed-address=10.200.0.0/24 persistent-keepalive=25s
/ip address add address=10.200.0.2/24 interface=wg-cloud
