Use dnsmasq and a PAC file to block unwanted web content, courtesy of [SecureMecca.com](http://securemecca.com).

##Part 1: Configure firewall/DNS server

###Step 1: Add firewall rules

```bash
cp /etc/firewall.user /etc/firewall.user.orig

FW1="iptables -t nat -I PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53"
FW2="iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53"

grep -q "$FW1" /etc/firewall.user || echo "$FW1" >> /etc/firewall.user
grep -q "$FW2" /etc/firewall.user || echo "$FW2" >> /etc/firewall.user
```

###Step 2: Add blacklist to dnsmasq config

```bash
cp /etc/dnsmasq.conf /etc/dnsmasq.conf.orig

DNS1="addn-hosts=/etc/blacklist.hosts"

grep -q "$DNS1" /etc/dnsmasq.conf || echo "$DNS1" >> /etc/dnsmasq.conf
```

###Step 3: Download hosts file

```bash
./get-hosts.sh
mv blacklist.hosts /etc/blacklist.hosts
```

Or do this step on another machine and upload the file:

```bash
scp hosts.txt root@192.168.1.1:/etc/blacklist.hosts
```

###Step 4: Restart firewall and dnsmasq

```bash
/etc/init.d/firewall restart; /etc/init.d/dnsmasq restart
```

###Step 5: Download PAC file

```bash
./get-pac.sh
mv blacklist.pac /www/blacklist.pac
```

##Part 2: Configure each host in the network

To set up a system-wide PAC file in Ubuntu, go to System Settings > Network > Network proxy. Change the method to automatic, and enter `http://192.168.1.1/blacklist.pac` for the configuration URL. This at least works for Chromium and Firefox.

See [here](http://www.ericphelps.com/security/pac.htm) for information on setting up a system-wide PAC file in Windows.

##Disclaimer

This is not a 100% effective solution for securing your network from adware, spyware, trojans, virses, smut, etc. But it will help.

