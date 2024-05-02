#!/bin/bash

# Read env data
readEnv() {
	# Путь к вашему файлу
	env_file=./env

	# Проверяем, существует ли файл
	if [ ! -f "${env_file}" ]; then
		printf "No env file: ${env_file}\n"
		exit 1
	fi
	# Read from env file
	while IFS='=' read -r key value; do
		printf "Key: $key, Value: $value\n"
		if [ "${key}" = "wg_dir" ]; then
			wg_dir=${value}
			wg0_path="${wg_dir}/wg0.conf"
		elif [ "${key}" = "mask" ]; then
			mask=${value}
		elif [ "${key}" = "public_add" ]; then
			public_add=${value}
		elif [ "${key}" = "ListenPort" ]; then
			ListenPort=${value}
		elif [ "${key}" = "server_pub_name" ]; then
			server_pub_name=${value}
		elif [ "${key}" = "server_priv_name" ]; then
			server_priv_name=${value}
		elif [ "${key}" = "DNS" ]; then
			DNS=${value}
		fi
	done < "${env_file}"

	# Check last string
	if [ -n "$key" ]; then
		printf "Key: $key, Value: $value\n"
		if [ "${key}" = "wg_dir" ]; then
			wg_dir=${value}
			wg0_path="${wg_dir}/wg0.conf"
		elif [ "${key}" = "mask" ]; then
			mask=${value}
		elif [ "${key}" = "public_add" ]; then
			public_add=${value}
		elif [ "${key}" = "ListenPort" ]; then
			ListenPort=${value}
		elif [ "${key}" = "server_pub_name" ]; then
			server_pub_name=${value}
		elif [ "${key}" = "server_priv_name" ]; then
			server_priv_name=${value}
		elif [ "${key}" = "DNS" ]; then
			DNS=${value}
		fi
	fi
	# Check if var is Empty
	if [ -z "${public_add}" ]; then
		public_add=$(curl -s ifconfig.me)
	fi
	if [ -z "${mask}" ]; then
		mask="10.0.8."
	fi
	if [ -n "${wg_dir}" ] && [ -n "${server_pub_name}" ] && [ -n "${server_priv_name}" ]; then
		server_pub_path="${wg_dir}/${server_pub_name}"
		server_priv_path="${wg_dir}/${server_priv_name}"
	else
		wg_dir="/etc/wireguard"
		wg0_path="${wg_dir}/wg0.conf"
		server_pub_path="${wg_dir}/server_publickey"
		server_priv_path="${wg_dir}/server_privatekey"
		wg genkey | tee ${server_priv_path} | wg pubkey | tee ${server_pub_path} > /dev/null
	fi
	if [ -z "${ListenPort}" ]; then
		ListenPort="51820"
	fi
	if [ -z "${DNS}" ]; then
		DNS="8.8.8.8"
	fi
}

# Init WG
init() {
    printf "\nInit\n"
	if systemctl list-unit-files --type=service | grep -q wg-quick; then
		if [ -f "${server_priv_path}" ]; then
			printf "[Interface]\nAddress = ${mask}1/24\nListenPort = ${ListenPort}\nPrivateKey = $(cat ${server_priv_path})\n" > ${wg0_path}
		else
			printf "No private key for server, check env file\n"
			exit 1
		fi
	else
		printf "Can't find WG installed\n"
		exit 1
	fi
}

#  Add user
userAdd() {
	printf "\nAdd user ${pref}\n"
	# Check private and public key for client
	client_private_path="${wg_dir}/${pref}_privatekey"
	client_public_path="${wg_dir}/${pref}_publickey"

	if [ ! -f ${client_private_path} ] && [ ! -f ${client_public_path} ]; then
		# Create public and private key for client
		wg genkey | tee ${client_private_path} | wg pubkey | tee ${client_public_path} > /dev/null
	fi

	priv=$(cat ${client_private_path})
	pub=$(cat ${client_public_path})

	# Find max IP in wg0.conf
	matches=$(grep -o "$mask[0-9]*" $wg0_path)
	numbers=$(echo "$matches" | awk -F'.' '{print $NF}')
	max_number=$(echo "$numbers" | sort -n | tail -n 1)
	((max_number++))

	printf "\n#${pref}\n[Peer]\nPublicKey = $(cat ${client_public_path})\nAllowedIPs = ${mask}${max_number}/32\n" >> ${wg0_path}
	conf_dir="${wg_dir}/conf/"
	if [ ! -d ${conf_dir} ]; then
		mkdir -p ${conf_dir}
	fi
	printf "\n#${pref}\n[Interface]\nPrivateKey = $(cat ${client_private_path})\nListenPort = ${ListenPort}\nAddress = ${mask}${max_number}/24\nDNS = ${DNS}\n\n[Peer]\nPublicKey = $(cat ${server_pub_path})\nAllowedIPs = ${mask}0/24\nEndpoint = ${public_add}:${ListenPort}\n\n" > ${conf_dir}${pref}.conf
}

# Check arg
if [ "${1}" = "--init" ]; then
	readEnv
    init
	printf "Init done\n"
	systemctl restart wg-quick@wg0.service
	exit 0
elif [ "${1}" = "--addUser" ]; then
    pref=${2}
	if [ -z "${pref}" ]; then
		printf "No name specified\n"
		exit 1
	fi
	readEnv
	userAdd
	printf "User add done\n"
	systemctl restart wg-quick@wg0.service
	exit 0
else
	printf "Unknown key\n"
	exit 1
fi
