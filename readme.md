A two part solution to network security that's good enough for me.

##Part 1: Blacklist

Do each of these steps on your firewall/DNS server.

###Step 1: Add firewall rules

```bash
cp /etc/firewall.user /etc/firewall.user.orig

fw1="iptables -t nat -I PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53"
fw2="iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53"

grep -q "$fw1" /etc/firewall.user || echo "$fw1" >> /etc/firewall.user
grep -q "$fw2" /etc/firewall.user || echo "$fw2" >> /etc/firewall.user
```

###Step 2: Add blacklist to dnsmasq config

```bash
cp /etc/dnsmasq.conf /etc/dnsmasq.conf.orig

dns1="addn-hosts=/etc/blacklist.hosts"

grep -q "$dns1" /etc/dnsmasq.conf || echo "$dns1" >> /etc/dnsmasq.conf
```

###Step 3: Download blacklist

```bash
./get-blacklist.sh
cp blacklist.hosts /etc/blacklist.hosts
```

Or do this on a separate host and upload the file to the server.

```bash
scp blacklist.hosts root@192.168.1.1:/etc/blacklist.hosts
```

###Step 4: Restart firewall and dnsmasq

```bash
/etc/init.d/firewall restart; /etc/init.d/dnsmasq restart
```

##Part 2: Failsafe

###Step 1: Register on OpenDNS

You can configure [OpenDNS](https://www.opendns.com/) to block just about anything. I prefer to leave it purely as a safety net, blocking only what slips through the blacklist.

###Step 2: Register on DNS-O-Matic

[DNS-O-Matic](https://www.dnsomatic.com/) provides an API to notify OpenDNS when your public IP address changes, which it needs to apply your filtering preferences. Add OpenDNS as a service to DNS-O-Matic.

###Step 3: Add startup script

This can go anywhere, but preferably on a host that is rebooted regularly.

```bash
cp /etc/rc.local /etc/rc.local.orig

rc1="/path/to/update-dns.sh &"

grep -q "$rc1" /etc/rc.local || echo "$rc1" >> /etc/rc.local
```

Or set up a cron job.

```bash
cp /etc/crontab /etc/crontab.orig

cron1="0 * * * * root /path/to/update-dns.sh"

grep -q "$cron1" /etc/crontab || echo "$cron1" >> /etc/crontab
```

###Step 4: Create config file

Create a file named `config.txt` in the same directory as the script. This file must contain your username and password for DNS-O-Matic and must be formatted as follows:

```text
update_ddns_user=username
update_ddns_pass=password
```

###Step 5: Add OpenDNS to dnsmasq config

Do this step on your DNS server.

```bash
#we already made a backup
#cp /etc/dnsmasq.conf /etc/dnsmasq.conf.orig

dns1="all-servers"
dns2="no-resolv"
dns3="server=208.67.222.222"
dns4="server=208.67.220.220"

grep -q "$dns1" /etc/dnsmasq.conf || echo "$dns1" >> /etc/dnsmasq.conf
grep -q "$dns2" /etc/dnsmasq.conf || echo "$dns2" >> /etc/dnsmasq.conf
grep -q "$dns3" /etc/dnsmasq.conf || echo "$dns3" >> /etc/dnsmasq.conf
grep -q "$dns4" /etc/dnsmasq.conf || echo "$dns4" >> /etc/dnsmasq.conf
```

###Step 6: Restart dnsmasq

```bash
/etc/init.d/dnsmasq restart
```

##Configuration

Configuration settings are read from a file named `config.txt` in the same directory as the scripts. The settings that can be specified are grouped by the script that uses them below. All settings must follow the syntax `key=value` with or without spaces around the `=` and without quotes around the `value`.

###get-blacklist.sh

* `blacklist_add_host`: Specify an additional domain to block. Can occur more than once.
* `blacklist_remove_host`: Unblock a domain. Can occur more than once.
* `blacklist_upload_dest`: The destination to upload the blacklist, formatted as user@host:file. If set, dnsmasq will be restarted automatically after the file is uploaded.

###update-dns.sh

* `update_ddns_user`: The username for DNS-O-Matic. This setting is required.
* `update_ddns_pass`: The password for DNS-O-Matic. This setting is required.
* `update_remote_ip`: The URL from which to obtain your public IP address. If unset, it will default to https://myip.dnsomatic.com.

##Disclaimer

This is not a 100% effective solution for securing your network from ads, malware, porn, trackers, etc. If you want that, you really need a [whitelist](https://github.com/Pajamaman/whitelist).

##Credit

Much love goes to the OpenWRT community, particularly those who contributed to [this thread](https://forum.openwrt.org/viewtopic.php?id=35023), to the folks at [Unix & Linux SE](https://unix.stackexchange.com/), [SecureMecca.com](http://securemecca.com/) and [MVPS.org](http://winhelp2002.mvps.org/).

