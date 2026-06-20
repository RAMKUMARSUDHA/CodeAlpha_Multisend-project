require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

// Pull sensitive values from .env (never hardcode private keys/API keys)
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    // Built-in local network used automatically when no --network flag is passed
    hardhat: {},

    // Local node started via `npx hardhat node` (run in a separate terminal)
    localhost: {
      url: "http://127.0.0.1:8545",
    },

    // Sepolia testnet — fill in SEPOLIA_RPC_URL and PRIVATE_KEY in .env to use
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};
