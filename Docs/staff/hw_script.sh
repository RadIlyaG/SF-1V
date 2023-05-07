
brctl addbr br0;
brctl addif br0 sfp1;
brctl addif br0 lan4;
ifconfig sfp1 up;
ifconfig lan4 up;
ifconfig br0 up;

brctl addbr br1;
brctl addif br1 lan4;
brctl addif br1 lan1;
ifconfig lan4 up;
ifconfig lan1 up;
ifconfig br1 up;

brctl addbr br2;
brctl addif br2 lan3;
brctl addif br2 lan2;
ifconfig lan2 up;
ifconfig lan3 up;
ifconfig br2 up;

rmmod mwifiex_pcie;
rmmod mwifiex;
insmod /lib/modules/4.19.128/drivers/net/wireless/marvell/mwifiex/mwifiex.ko driver_mode=0x3;
insmod /lib/modules/4.19.128/drivers/net/wireless/marvell/mwifiex/mwifiex_pcie.ko;
sleep 5

hostapd -B /etc/hostapd/hostapd.conf

if [ -z $1 ]; then
        echo "missing apn parameter"
        exit 1
fi
apn_name=$1

/root/quectel/quectel-CM -s $apn_name &