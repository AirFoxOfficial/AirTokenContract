var AirToken = artifacts.require("./AirToken.sol");

module.exports = function(deployer, network, accounts) {
    // Deploy AirToken contract, first account for receviing eth,
    // second for the AT fund
    console.log("Accounts", accounts);
    deployer.deploy(AirToken, accounts[0], accounts[1], 0, 100000);
};
