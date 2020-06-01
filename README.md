A two part solution to network security that's good enough for me.

## Part 1: Blacklist

Do each of these steps on your firewall/DNS server.

### Step 1: Configure firewall

These firewall rules will prevent clients on the network from bypassing the
DNS server:

```
iptables -t nat -I PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53
```

Restart the firewall.

### Step 2: Configure dnsmasq

Run `get-blacklist.sh` to download the blacklist, then add this to the dnsmasq
configuration file (typically at `/etc/dnsmasq.conf`):

```
addn-hosts=/path/to/blacklist.hosts
```

Restart dnsmasq.

### Step 3 (optional): Configure crontab

This cron job will run `get-blacklist.sh` once per month, but will only
download a new blacklist if it has changed:

```
0 0 1 * * /path/to/get-blacklist.sh
```

## Part 2: Failsafe

### Step 1: Register on OpenDNS

You can configure [OpenDNS](https://www.opendns.com/) to block just about
anything. I prefer to leave it purely as a safety net, blocking only what
slips through the blacklist.

### Step 2: Register on DNS-O-Matic

[DNS-O-Matic](https://www.dnsomatic.com/) provides an API to notify OpenDNS
when your public IP address changes, which it needs to apply your filtering
preferences. Add OpenDNS as a service to DNS-O-Matic.

### Step 3: Configure dnsmasq

Add this to the dnsmasq configuration file (typically at `/etc/dnsmasq.conf`)
to use the OpenDNS nameservers:

```
all-servers
no-resolv
server=208.67.222.222
server=208.67.220.220
```

Restart dnsmasq.

### Step 4: Create config file

Create a file named `config.txt` in the same directory as `update-ddns.sh`.
This file must contain your username and password for DNS-O-Matic and must be
formatted as follows:

```
ddns_user=username
ddns_pass=password
```

### Step 5: Configure crontab

This cron job will run `update-ddns.sh` every ten minutes, but will only send
an update to DNS-O-Matic if your public IP address has changed:

```
*/10 * * * * /path/to/update-ddns.sh
```

## Configuration

Configuration settings are read from a file named `config.txt`. It must live
in the same directory as the script that uses it. All settings must follow the
syntax `key=value` with or without spaces around the `=` and without quotes
around the `value`.

### get-blacklist.sh

* `blacklist_add_host`: Specify an additional domain to block. Can occur more
  than once.
* `blacklist_remove_host`: Unblock a domain. Can occur more than once.
* `blacklist_upload_dest`: The destination to upload the blacklist, formatted
  as user@host:file. This is useful in case you want to run `get-blacklist.sh`
  from any host other than your firewall/DNS server. If set, dnsmasq will be
  restarted automatically after the file is uploaded.

### update-ddns.sh

* `ddns_user`: The username for DNS-O-Matic. This setting is required.
* `ddns_pass`: The password for DNS-O-Matic. This setting is required.
* `ddns_ip_src`: The URL from which to obtain your public IP address.  If
  unset, it will default to http://myip.dnsomatic.com.
* `ddns_ca_dir`: The SSL certificate directory. If unset, it will default to
  /etc/ssl/certs.

## Additional setup for OpenWrt

In order for this script to run on OpenWrt, you must install ca-certificates
and curl:

```sh
$ opkg install ca-certificates curl
```

In addition, you must enable cron:

```sh
$ /etc/init.d/cron start
$ /etc/init.d/cron enable
```

You can get your public IP address without hitting an external URL. Create
a shell script at `/www/cgi-bin/ip` with something like the following:

```sh
#!/usr/bin/env sh

echo -e 'Content-Type: text/plain\n'
ip -4 addr show eth1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1
```

Make the script executable:

```sh
$ chmod +x /www/cgi-bin/ip
```

Then add this to `config.txt`:

```
ddns_ip_src=http://127.0.0.1/cgi-bin/ip
```

## Alternatives

I didn't have this option when I wrote this guide, but these days it's probably
more practical for most people to use the [AdGuard](https://adguard.com/)
Family Protection nameservers. It's not as configurable as OpenDNS, but it only
requires step 3 from part 2 above. Just replace the last two lines of the
dnsmasq configuration file with AdGuard's nameservers:

```
all-servers
no-resolv
server=176.103.130.132
server=176.103.130.134
```

Of course, many other alternatives exist as well, but I'll leave the research
to you.

## Disclaimer

This is not a 100% effective solution for securing your network from ads,
malware, porn, trackers, etc. If you want that, you really need a
[whitelist](https://github.com/dave-kennedy/whitelist).

## Credit

Much love goes to the OpenWRT community, particularly those who contributed to
[this thread](https://forum.openwrt.org/viewtopic.php?id=35023), and to the
folks at [Unix & Linux SE](https://unix.stackexchange.com/),
[SecureMecca.com](http://securemecca.com/) and
[MVPS.org](http://winhelp2002.mvps.org/).
