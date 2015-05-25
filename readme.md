Use dnsmasq and a PAC file to block unwanted web content, courtesy of [SecureMecca.com](http://securemecca.com).

##Part 1: Do this on the firewall/DNS server

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
mv hosts.txt /etc/blacklist.hosts
```

Or do this step on another machine and upload the file:

```bash
scp hosts.txt root@192.168.1.1:/etc/blacklist.hosts
```

###Step 4: Restart firewall and dnsmasq

```bash
/etc/init.d/firewall restart; /etc/init.d/dnsmasq restart
```

##Part 2: Do this on each host in the network

###Step 1: Download PAC file

```bash
./get-pac.sh
mv pac.txt /etc/blacklist.pac
```

On a Windows system, this file can go in `C:\Windows\system32\drivers\etc\`.

###Step 2: Configure each browser to use the PAC file

This is the least fun step, and varies for each browser/OS.

To set up a system-wide PAC file in Ubuntu, go to System Settings > Network > Network proxy. Change the method to automatic, and enter `file:///etc/blacklist.pac` for the configuration URL. This at least works for Chromium and Firefox.

See [here](http://www.ericphelps.com/security/pac.htm) for information on setting up a system-wide PAC file in Windows.

##Disclaimer

This is not a 100% effective solution for securing your network from adware, spyware, trojans, virses, smut, etc. But it will help.

