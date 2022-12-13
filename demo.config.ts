const NetworkDefinition = {
  rinkeby: {
    url: "https://rinkeby.infura.io/v3/*******your-api-key*******",
    accounts: {
      mnemonic: "test test test test test test test test test test test junk",
    },
  },
  polygon: {
    url: "https://polygon.infura.io/v3/*******your-api-key*******",
    accounts: {
      mnemonic: "test test test test test test test test test test test junk",
    },
  },
};
const EtherscanConfig = {
  apiKey: "YOUR_ETHERSCAN_API_KEY",
};

export { NetworkDefinition, EtherscanConfig };
