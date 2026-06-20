# MultiSend Project

A Hardhat project for compiling, testing, and deploying the `MultiSend` smart contract,
which splits Ether equally among multiple recipient addresses in a single transaction.

## Project Structure

```
multisend-project/
├── contracts/
│   ├── MultiSend.sol           # Main contract
│   └── RevertingReceiver.sol   # Test-only helper (rejects Ether, used in tests)
├── scripts/
│   └── deploy.js               # Deployment script
├── test/
│   └── MultiSend.test.js       # Full test suite (happy path + edge cases)
├── hardhat.config.js
├── package.json
├── .env.example
└── .gitignore
```

## Setup (in VS Code terminal)

1. Open this folder in VS Code: `File > Open Folder...`
2. Open a terminal: `` Ctrl+` `` (or `View > Terminal`)
3. Install dependencies:
   ```bash
   npm install
   ```
4. (Optional) Set up environment variables for testnet deployment:
   ```bash
   cp .env.example .env
   ```
   Then edit `.env` and fill in `SEPOLIA_RPC_URL`, `PRIVATE_KEY`, and `ETHERSCAN_API_KEY`.

## Compile

```bash
npm run compile
```

## Run Tests

```bash
npm test
```

This runs the full suite in `test/MultiSend.test.js`, covering:
- Equal distribution across recipients
- Empty array rejection
- Zero Ether rejection
- Amount too small to split (rounds to 0 per recipient)
- Zero address rejection
- Dust (rounding remainder) handling and owner withdrawal
- Non-owner withdrawal rejection
- Direct Ether transfer rejection
- Full batch revert when one recipient's transfer fails

## Deploy Locally

In one terminal, start a local Hardhat node:
```bash
npx hardhat node
```

In a second terminal, deploy to it:
```bash
npm run deploy:local
```

## Deploy to Sepolia Testnet

Make sure `.env` is filled in, then:
```bash
npm run deploy:sepolia
```

## Verify on Etherscan (after Sepolia deployment)

```bash
npx hardhat verify --network sepolia <deployed_contract_address>
```

## Notes

- `RevertingReceiver.sol` is for testing only — it has no purpose in production and
  doesn't need to be deployed alongside `MultiSend`.
- Any leftover wei from integer-division rounding stays in the contract and can be
  swept out by the owner via `withdrawDust()`.
