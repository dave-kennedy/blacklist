A three part solution for network security that's good enough for me.

##Part 1: Blacklist

Do each of these steps on your firewall/DNS server.

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

###Step 3: Download blacklist

```bash
./get-hosts.sh
mv blacklist.hosts /etc/blacklist.hosts
```

###Step 4: Restart firewall and dnsmasq

```bash
/etc/init.d/firewall restart; /etc/init.d/dnsmasq restart
```

##Part 2: Filter

###Step 1: Download filter

If you have a web server, download this file to the web root or something.

```bash
./get-pac.sh
mv filter.pac /www/filter.pac
```

If you don't have a web server, you can download it to a file share or to each host in the network. My firewall/DNS server is also a web server, so I put it there.

###Step 2: Configure clients

Each host in the network will need to be configured to use the PAC file. This step varies for each browser/OS, but most browsers use the system-wide proxy settings.

To set up a system-wide proxy in Ubuntu, go to System Settings > Network > Network proxy. Change the method to automatic, and enter the path to the PAC file for the configuration URL. This at least works for Chromium and Firefox.

See [here](http://www.ericphelps.com/security/pac.htm) for information on setting up a system-wide proxy in Windows.

##Part 3: Failsafe

###Step 1: Register on OpenDNS

[OpenDNS](https://www.opendns.com/)

You can configure OpenDNS to block everything from alcohol to email, weapons and even religion. I prefer to leave it purely as a safety net, blocking only malware and porn, in case something slips through the blacklist and the proxy.

###Step 2: Register on DNS-O-Matic

[DNS-O-Matic](https://www.dnsomatic.com/)

Add OpenDNS as a service to DNS-O-Matic.

###Step 3: Add startup script

This can go anywhere, but preferably on a host that is rebooted regularly.

```bash
cp /etc/rc.local /etc/rc.local.orig

RC1="/path/to/update-dns.sh &"

grep -q "$RC1" /etc/rc.local || echo "$RC1" >> /etc/rc.local
```

###Step 4: Add OpenDNS to dnsmasq config

Do this step on your DNS server.

```bash
#we already made a backup
#cp /etc/dnsmasq.conf /etc/dnsmasq.conf.orig

DNS1="all-servers"
DNS2="no-resolv"
DNS3="server=208.67.222.222"
DNS4="server=208.67.220.220"

grep -q "$DNS1" /etc/dnsmasq.conf || echo "$DNS1" >> /etc/dnsmasq.conf
grep -q "$DNS2" /etc/dnsmasq.conf || echo "$DNS2" >> /etc/dnsmasq.conf
grep -q "$DNS3" /etc/dnsmasq.conf || echo "$DNS3" >> /etc/dnsmasq.conf
grep -q "$DNS4" /etc/dnsmasq.conf || echo "$DNS4" >> /etc/dnsmasq.conf
```

###Step 5: Restart dnsmasq

```bash
/etc/init.d/dnsmasq restart
```

##Customization

Since the blacklist is downloaded from [SecureMecca.com](http://securemecca.com/), any changes made to it will be lost when the script is run again. Additional domains can be added to a file named `add-hosts.txt`. This file should live in the same directory as the script and should be formatted as a hosts file:

```text
127.0.0.1    4chan.org
```

Likewise, additional proxy rules can be added to a file named `add-pac.txt`. It should look like this:

```text
BadURL_Parts[i++] = "foobar"
BadHostParts[i++] = "[^e]adult";
```

See [here](http://securemecca.com/Downloads/proxy_en.txt) for the complete list and description of each section.

##Disclaimer

This is not a 100% effective solution for securing your network from ads, malware, porn, trackers, etc. If you want that, you really need a [whitelist](https://github.com/Pajamaman/dnsmasq).

##To-do

* get-hosts.sh
  * Upload to DNS server
  * Skip download and build blacklist.hosts
* get-pac.sh
  * Upload to web server/network share
  * Skip download and build filter.pac
