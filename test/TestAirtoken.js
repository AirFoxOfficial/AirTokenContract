var AirToken = artifacts.require("./AirToken.sol");

contract('AirToken', function(accounts) {

    var ETHER_FOR_AIRTOKENS = 5;
    var ETHER_WORTH_OF_AIRTOKENS_TO_TRANSFER = 2;
    
    var US_MDN = web3.fromAscii("16175555555", 32);
    var UK_MDN = web3.fromAscii("442055551234", 32);
    var TESTING_MDN = US_MDN;

    it("Should be a no-op", function() {
    
        assert(true);
    });

    it("Buys " + ETHER_FOR_AIRTOKENS + " ether worth of AirTokens", function() {

        var instance;
        var exchangeRate;

        AirToken.deployed().then(function(ins) {
            instance = ins;
            return instance.tokenExchangeRate();
        }).then(function(result) {
            exchangeRate = result.toNumber();
            //console.log("exchange rate", exchangeRate)
            
            return instance.createTokens({from: accounts[2], value: web3.toWei(ETHER_FOR_AIRTOKENS, "ether")});
        }).then(function(result) {
            return instance.balanceOf.call(accounts[2], {from: accounts[2]})
        }).then(function(result) {
            assert(result.dividedBy(10**18).dividedBy(exchangeRate).equals(ETHER_FOR_AIRTOKENS));
        });

    });

    it("Buys " + ETHER_FOR_AIRTOKENS + " ether worth of AirTokens and " +
       "transfers to internal ledger, and verifies MDN in event log", function() {

        var instance;
        var initialReserveATBalance;

        AirToken.deployed().then(function(ins) {
            instance = ins;
            return instance.balanceOf.call(accounts[1], {from: accounts[3]});
        }).then(function(result) {
            initialReserveATBalance = result;

            return instance.createTokens({from: accounts[3], value: web3.toWei(ETHER_FOR_AIRTOKENS, "ether")});
        
        }).then(function(result) {
            
            return instance.transferToInternalLedger(
                web3.toWei(ETHER_WORTH_OF_AIRTOKENS_TO_TRANSFER, "ether"),
                TESTING_MDN, {from: accounts[3]});

        }).then(function(result) {
            return instance.balanceOf.call(accounts[1], {from: accounts[3]});
        
        }).then(function(result) {
            
            // Verify AirToken reserve was incremented correctly
            assert(initialReserveATBalance.lessThan(result));
            assert(initialReserveATBalance.plus(web3.toWei(ETHER_WORTH_OF_AIRTOKENS_TO_TRANSFER, "ether"))
                .equals(result));

            // Check that MDN properly logged
            web3.eth.filter({
              address: instance.address,
              fromBlock: 0,
              toBlock: 'latest'
            }).get(function (err, result) {

              var testingMdn = web3.toAscii(TESTING_MDN);
              // The MDN in the log does not remove the padding, might be a bug related to
              // https://github.com/ethereum/web3.js/issues/337
              var loggedMdn = web3.toAscii(result[result.length-1].topics[3]).substring(0, testingMdn.length);
              
              assert(loggedMdn == testingMdn);
            })

        });
    });
});
