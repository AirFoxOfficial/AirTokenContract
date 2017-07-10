pragma solidity ^0.4.10;
import "./StandardToken.sol";
import "./SafeMath.sol";

contract AirToken is StandardToken, SafeMath {

    // metadata
    string public constant name = "AirToken";
    string public constant symbol = "AT";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public ethFundDeposit; // deposit address for ETH for AirFox
    address public atFundDeposit;  // deposit address for AirFox use and AT User Fund

    // crowdsale parameters
    bool public isFinalized; // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public constant atFund = 500 * (10**9) * 10**decimals;   // 500 billion AT reserved for AirFox
    uint256 public constant tokenExchangeRate = 8750000; // 8,750,000 AT tokens per 1 ETH
    uint256 public constant tokenCreationCap =  1500 * (10**9) * 10**decimals;


    // events
    event CreateAT(address indexed _to, uint256 _value);
    event TransferInternalLedgerAT(address indexed _from, address _to, uint256 indexed _value, bytes32 indexed mdn);

    // constructor
    function AirToken(
        address _ethFundDeposit,
        address _atFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock)
    {
      isFinalized = false;                   //controls pre through crowdsale state
      ethFundDeposit = _ethFundDeposit;
      atFundDeposit = _atFundDeposit;
      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
      totalSupply = atFund;
      balances[atFundDeposit] = atFund;    // Deposit AirFox share
      CreateAT(atFundDeposit, atFund);  // logs AirFox fund
    }

    /// @dev Accepts ether and creates new AirTokens
    function createTokens() payable external {
      if (isFinalized) throw;
      if (block.number < fundingStartBlock) throw;
      if (block.number > fundingEndBlock) throw;
      if (msg.value == 0) throw;

      // Remember that 1 ether = 10^18 wei, and msg.value is in wei
      // Refer to BAT issue for someone else who was confused:
      //      https://github.com/brave-intl/basic-attention-token-crowdsale/issues/13
      uint256 tokens = safeMult(msg.value, tokenExchangeRate); // check that we're not over totals
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

      // return money if something goes wrong
      if (tokenCreationCap < checkedSupply) throw;  // odd fractions won't be found

      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;  // safeAdd not needed
      CreateAT(msg.sender, tokens);  // logs token creation
    }

    /// @dev Ends the funding period and sends the ETH home
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != ethFundDeposit) throw; // locks finalize to the ultimate ETH owner
      if (block.number <= fundingEndBlock && totalSupply != tokenCreationCap) throw;
      // move to operational
      isFinalized = true;
      if (!ethFundDeposit.send(this.balance)) throw;  // send the eth to AirFox
    }

    /// Transfer a number of AirTokens to the internal AirFox ledger address
    /// by a user's MDN, digits only including country code, no white space, dashes,
    /// plusses, or any other special characters. Encode using web3.fromAscii()
    /// with 32 bytes as the length. If you don't encode the MDN properly, they
    /// won't receive the AirTokens.
    ///
    /// Example for US number (country code 1):  16175551234
    ///     web3.fromAscii("16175555555", 32);
    /// Example for UK number (country code 44): 442055551234
    ///     web3.fromAscii("442055551234", 32);
    function transferToInternalLedger(uint256 _value, bytes32 _mdn) external returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[atFundDeposit] += _value;
        TransferInternalLedgerAT(msg.sender, atFundDeposit, _value, _mdn);
        return true;
      } else {
        return false;
      }
    }

}