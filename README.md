# wg-init 
Simple bash script for wireguard initialization 

Usage: 
Script can: 

1) Initialize an WG Server 
2) Create a client config 

WG should be already installed on system before running script

To init wg server:
```bash
root May 3 1:53 /etc/scripts > ./main.sh --init
Key: wg_dir, Value: /etc/wireguard
Key: mask, Value: 10.0.8.
Key: server_pub_name, Value: server_publickey
Key: server_priv_name, Value: server_privatekey
Key: ListenPort, Value: 51820
Key: DNS, Value: 8.8.8.8

Init
Init done
```

Script will generate and rewrite everything inside wg0.conf

```bash
root May 3 2:19 /etc/scripts > head -n 4 /etc/wireguard/wg0.conf
[Interface]
Address = <mask1/24> # if '10.0.8.' in mask - `10.0.8.1/24`
ListenPort = 51820 # Could be changed in env file
PrivateKey = <you will see server private key here>
```

To add new user:
```bash
root May 3 2:10 /etc/scripts > ./main.sh --addUser Newuser
Key: wg_dir, Value: /etc/wireguard
Key: mask, Value: 10.0.8.
Key: server_pub_name, Value: server_publickey
Key: server_priv_name, Value: server_privatekey
Key: ListenPort, Value: 51820
Key: DNS, Value: 8.8.8.8

Add user Newuser
User add done
```

After you can find user config in:
`${wg_dir}/conf/${userName}.conf`
```bash
root May 3 2:12 /etc/wireguard > cat /etc/wireguard/conf/Newuser.conf
#Newuser
[Interface]PrivateKey = <you will see client private key here>
ListenPort = 51820 # Could be changed in env file
Address = <you will see wg ip for client here>
DNS = 8.8.8.8

[Peer]
PublicKey = <you will see server public key here>
AllowedIPs = 10.0.8.0/24 # Allow all WG IPs 
Endpoint = <You will see server IP and port here>
```

Also script will create new peer block inside wg0.conf
```bash
root May 3 2:17 /etc/scripts > tail -n 4 /etc/wireguard/wg0.conf
#Newuser
[Peer]
PublicKey = <you will see user public key here>
AllowedIPs = (highest used ip in wg0.conf + 1)/24 
```
