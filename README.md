# CAT20Hattimon v1 Script

`cat20hattimon-v1.sh` is a bash script for setting up and managing a full node environment, creating wallets, deploying CAT20 tokens, minting tokens, transferring tokens, and more. The script simplifies the process of deploying and managing tokens on a blockchain node.

## Features
- Install the full node and necessary environment
- Deploy CAT20 tokens
- Create and manage wallets
- Mint tokens automatically
- Transfer tokens to other addresses
- View node logs and check wallet balances

## Installation Instructions

### Step 1: Switch to Root User

To ensure the script runs with the necessary permissions, switch to the root account:

```bash
sudo su
```

### Step 2: Clone the Repository

Navigate to the root directory and clone the repository containing the script:

```bash
cd /root
git clone https://github.com/hattimon/cat-token-box.git
```

### Step 3: Make the Script Executable

Once the repository is cloned, navigate to its directory and make the script executable:

```bash
cd cat-token-box
chmod +x cat20hattimon-v1.sh
```

### Step 4: Run the Script

Now you can run the script to install the environment and manage your node. The script provides a menu to guide you through various operations:

```bash
./cat20hattimon-v1.sh
```

## Script Menu Options

When you run the script, you will be presented with a menu of options:

1. **Install Environment and Full Node**  
   The script will install all necessary packages and set up a full node.

2. **Create Wallet**  
   Create a new wallet and generate an address.

3. **Deploy Token**  
   Deploy a new CAT20 token by entering details such as token name, symbol, supply, etc.

4. **Export Mnemonic**  
   Export your wallet’s recovery phrases (mnemonic) for backup.

5. **Import Mnemonic**  
   Import a wallet using recovery phrases (mnemonic).

6. **Start Minting CAT Tokens**  
   Automatically mint tokens using a specified token ID.

7. **Check Node Logs**  
   View the latest logs of the running node.

8. **Check Wallet Balance**  
   Check the balance of your created wallet.

9. **Send Token**  
   Transfer tokens by providing the token ID, recipient address, and amount.

A. **Show Wallet Address**  
   Display the wallet address associated with your created wallet.

0. **Exit**  
   Exit the script.

## Example Workflow

1. **Install the Full Node**  
   Select option 1 to install the required environment and packages.

2. **Create a Wallet**  
   Use option 2 to create a wallet and note down the address and mnemonic.

3. **Deploy a Token**  
   Choose option 3 to deploy a new CAT20 token by entering the required details.

4. **Mint Tokens**  
   Use option 6 to mint tokens continuously with the token ID.

## License

This script is licensed under the MIT License. See `LICENSE` for details.
