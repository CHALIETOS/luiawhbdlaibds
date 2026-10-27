  GNU nano 8.7.1                                                                                                  prueba.sh                                                                                                           
# --- VARIABLES ---
INT_LAN="enp6s0"   # Interfaz conectada al cliente (tu compañero/a)
INT_WAN="enp1s0"   # Interfaz conectada al switch/Internet
IP_ROUTER="10.0.1.1/24"

# Comprobar si se ejecuta con sudo
if [ "$EUID" -ne 0 ]; then
    echo "Ejecuta con sudo: sudo $0 {start|stop}"
    exit 1
fi

case "$1" in
    start)
        echo "[+] Activando Router..."
        # 1. Asignar IP y levantar la interfaz LAN
        ip a add "$IP_ROUTER" dev "$INT_LAN"
        ip link set dev "$INT_LAN" up

        # 2. Activar el reenvío de paquetes en el kernel
        sysctl -w net.ipv4.ip_forward=1

        # 3. Aplicar regla de NAT (Masquerade) en la interfaz WAN
        iptables -t nat -A POSTROUTING -o "$INT_WAN" -j MASQUERADE
        echo "[OK] Router configurado y activo."
        ;;
    stop)
        echo "[-] Desactivando Router..."

        # 1. Quitar regla de NAT
        iptables -t nat -D POSTROUTING -o "$INT_WAN" -j MASQUERADE 2>/dev/null || true

        # 2. Desactivar el reenvío de paquetes
        sysctl -w net.ipv4.ip_forward=0

        # 3. Eliminar la IP y bajar la interfaz LAN
        ip a del "$IP_ROUTER" dev "$INT_LAN" 2>/dev/null || true
        ip link set dev "$INT_LAN" down

        echo "[OK] Router desactivado."
        ;;
    *)
        echo "Uso: sudo $0 {start|stop}"
        exit 1
        ;;
esac

