#!/bin/bash

Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}Info${Font_color_suffix}]"
Error="[${Red_font_prefix}Error${Font_color_suffix}]"
Tip="[${Green_font_prefix}Tip${Font_color_suffix}]"

check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} You currently do not have ROOT privileges (or are not using the ROOT account), operation cannot continue. Please switch to the ROOT account or use ${Green_background_prefix}sudo su${Font_color_suffix} to obtain temporary ROOT privileges (you may need to provide the current account password)." && exit 1
}

install_env_and_full_node() {
    check_root
    sudo apt update && sudo apt upgrade -y
    sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make docker.io -y
    VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
    DESTINATION=/usr/local/bin/docker-compose
    sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
    sudo chmod 755 $DESTINATION

    sudo apt-get install npm -y
    sudo npm install n -g
    sudo n stable
    sudo npm i -g yarn

    git clone https://github.com/CATProtocol/cat-token-box
    cd cat-token-box
    sudo yarn install
    sudo yarn build

    MAX_CPUS=$(nproc)
    MAX_MEMORY=$(free -m | awk '/Mem:/ {print int($2*0.8)"M"}')

    cd ./packages/tracker/
    sudo chmod 777 docker/data
    sudo chmod 777 docker/pgdata
    sudo docker-compose up -d

    cd ../../
    sudo docker build -t tracker:latest .
    sudo docker run -d \
        --name tracker \
        --cpus="$MAX_CPUS" \
        --memory="$MAX_MEMORY" \
        --add-host="host.docker.internal:host-gateway" \
        -e DATABASE_HOST="host.docker.internal" \
        -e RPC_HOST="host.docker.internal" \
        -p 3000:3000 \
        tracker:latest
    echo '{
      "network": "fractal-mainnet",
      "tracker": "http://127.0.0.1:3000",
      "dataDir": ".",
      "maxFeeRate": 30,
      "rpc": {
          "url": "http://127.0.0.1:8332",
          "username": "bitcoin",
          "password": "opcatAwesome"
      }
    }' > ~/cat-token-box/packages/cli/config.json
}

create_wallet() {
  echo -e "\n"
  cd ~/cat-token-box/packages/cli
  sudo yarn cli wallet create
  echo -e "\n"
  sudo yarn cli wallet address
  echo -e "Please save your wallet address and recovery phrases (mnemonic)"
}

deploy_token() {
  # Fetch parameters from the user
  read -p "Enter token name: " tokenName
  read -p "Enter token symbol: " tokenSymbol
  read -p "Enter decimals: " decimals
  read -p "Enter maximum supply of tokens: " maxSupply
  read -p "Enter amount for premine: " premine
  read -p "Enter minting limit: " limit
  
  # Execute deploy command
  cd ~/cat-token-box/packages/cli
  sudo yarn cli deploy --name=$tokenName --symbol=$tokenSymbol --decimals=$decimals --max=$maxSupply --premine=$premine --limit=$limit

  # Extract TokenId after deployment
  if [ $? -eq 0 ]; then
      echo -e "${Info} Token $tokenSymbol has been successfully deployed."
      
      # Retrieve TokenId
      echo -e "${Info} Checking TokenId..."
      tokenId=$(sudo yarn cli wallet balances | grep -oP "'[a-f0-9]{64}_[0-9]+'")
      echo -e "Your TokenId: $tokenId"
      echo -e "TokenId will be needed for minting and transferring tokens."
  else
      echo -e "${Error} Failed to deploy token, please check the data and try again."
  fi
}

export_mnemonic() {
    # Check if wallet.json file exists
    if [ -f ~/cat-token-box/packages/cli/wallet.json ]; then
        # Extract mnemonic from wallet.json
        mnemonic=$(jq -r '.mnemonic' ~/cat-token-box/packages/cli/wallet.json)
        echo -e "${Info} Your mnemonic: $mnemonic"
    else
        echo -e "${Error} The wallet.json file does not exist."
    fi
}

import_mnemonic() {
    # Get new mnemonic from the user
    read -p "Enter new mnemonic: " newMnemonic

    # Check if wallet.json file exists
    if [ -f ~/cat-token-box/packages/cli/wallet.json ]; then
        # Update the mnemonic in wallet.json
        jq --arg newMnemonic "$newMnemonic" '.mnemonic = $newMnemonic' ~/cat-token-box/packages/cli/wallet.json > ~/cat-token-box/packages/cli/wallet_new.json
        mv ~/cat-token-box/packages/cli/wallet_new.json ~/cat-token-box/packages/cli/wallet.json
        echo -e "${Info} Mnemonic has been updated."
    else
        echo -e "${Error} The wallet.json file does not exist."
    fi
}

show_wallet_address() {
    cd ~/cat-token-box/packages/cli
    sudo yarn cli wallet address
}

start_mint_cat() {
  # Fetch TokenId
  read -p "Enter TokenId for minting: " tokenId

  # Fetch gas (maxFeeRate)
  read -p "Set gas (maxFeeRate) for minting: " newMaxFeeRate
  sed -i "s/\"maxFeeRate\": [0-9]*/\"maxFeeRate\": $newMaxFeeRate/" ~/cat-token-box/packages/cli/config.json

  # Fetch minting amount
  read -p "Enter amount to mint: " amount

  cd ~/cat-token-box/packages/cli

  # Mint command with TokenId and amount
  command="sudo yarn cli mint -i $tokenId $amount"

  # Minting loop
  while true; do
      $command

      if [ $? -ne 0 ]; then
          echo "Command execution failed, exiting loop"
          exit 1
      fi

      sleep 1
  done
}

check_node_log() {
  docker logs -f --tail 100 tracker
}

check_wallet_balance() {
  cd ~/cat-token-box/packages/cli
  sudo yarn cli wallet balances
}

send_token() {
  read -p "Enter TokenId (not token name): " tokenId
  read -p "Enter recipient address: " receiver
  read -p "Enter amount to send: " amount
  cd ~/cat-token-box/packages/cli
  sudo yarn cli send -i $tokenId $receiver $amount
  if [ $? -eq 0 ]; then
      echo -e "${Info} Token transfer successful"
  else
      echo -e "${Error} Token transfer failed, check the data and try again"
  fi
}

echo -e "${Green_font_prefix}Welcome to the CAT20 Tracker CLI script HATTIMON v1 Edition ${Font_color_suffix}"
echo -e "Select an option:"
echo -e "1. Install environment and full node"
echo -e "2. Create wallet"
echo -e "3. Deploy token"
echo -e "4. Export mnemonic"
echo -e "5. Import mnemonic"
echo -e "6. Start minting CAT"
echo -e "7. Check node logs"
echo -e "8. Check wallet balance"
echo -e "9. Send token"
echo -e "A. Check wallet address"
echo -e "0. Exit"

read -p "Select an option: " option

case $option in
  1) install_env_and_full_node ;;
  2) create_wallet ;;
  3) deploy_token ;;
  4) export_mnemonic ;;
  5) import_mnemonic ;;
  6) start_mint_cat ;;
  7) check_node_log ;;
  8) check_wallet_balance ;;
  9) send_token ;;
  A) show_wallet_address ;;
  0) exit 0 ;;
  *) echo -e "${Error} Invalid option" ;;
esac
