// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

abstract contract ERC20DecentrToken {
    // Allows token minting
    function mintToken(address to, uint256 value) external virtual returns (bool success);

    // Pauses token use
    function pause() external virtual;

    // Unpauses token use
    function unpause() external virtual;
}

/**
 * @dev Pausable specifies if trade is opened or not.
 * @dev Ownable is keeping track of owner of the
 */
contract DecentrSaleContract is Ownable, Pausable {
    // Amount of max Mintable tokens
    uint256 private _maxMintable = 10**27;

    // Amount of total minted tokens
    uint256 private _totalMinted;

    // Blocks identifiers to keep track of contract life
    uint private _startBlock;
    uint private _lastBlock;

    // Mutable ETH <-> Token rate
    uint private _exchangeRate;

    // Wallet which will act like an ICO
    address payable private ETHWallet;

    // Token as a main point of trading in the contract.
    ERC20DecentrToken public DecentrToken;
    bool private tokenInitialized;

    // Promised tokens information.
    // Stores information about tokens to be released at some certain point of time.
    struct TimeLockedTokenInfo {
        uint256 tokensAmount;
        uint releaseDate;
        uint createdAt;
        bool isEntity; // Represents check for whether struct exists.
    }

    // Stores information about the tokens that should and heldTimeline
    mapping(address => TimeLockedTokenInfo) private timeLockedTokens;

    // Flag for initialization checks
    bool private _initializationCompleted = false;

    event ExchangeRateUpdate(uint amountOfTokensForEthereum);
    event TimeLockedTokensRelease(address to, uint256 tokensAmount);
    event Contribution(address from, uint256 amount);
    event ContractStateUpdated(bool isPaused);

    constructor () public {
        // !Important: Enabling pause to refuse Ether receiving
        closeTrade();

        // Registers block which is the first bloc of contract life
        _startBlock = block.number;
    }

    /**
    * @dev Allows admin to register delayed tokens sending by creating a record of how much tokens should be sent to receiver after some date.
    */
    function registerTimeLockedTokens(address receiver, uint tokensAmount, uint releaseDate) public onlyOwner returns (bool success) {

        require(receiver != address(0), 'DecentrSaleContract: Receiver address must not be empty.');
        require(tokensAmount > 0, 'DecentrSaleContract: Tokens amount should be defined.');
        require(releaseDate >= now, 'DecentrSaleContract: Release date should be in future.');

        // Calculating total amount of minted tokens
        uint256 total = _totalMinted + tokensAmount;

        // Restrict amount of mintable tokens
        require(total <= _maxMintable, 'DecentrSaleContract: Amount of tokens to be minted exceeds the max tokens allowed amount.');

        // Adding information about the time locked tokens for address
        timeLockedTokens[receiver] = TimeLockedTokenInfo(tokensAmount, releaseDate, now, true);

        _totalMinted += tokensAmount;

        return true;
    }

    /**
     * @dev Allows user to check if there are some tokens that can be released.
     */
    function canReceiveTimeLockedTokens() public view returns (bool canReceive) {
        return _canReleaseTimeLockedTokens(msg.sender);
    }

    /**
     * @dev Allows owner to check if there are some tokens that can be released for receiver.
     */
    function canReleaseTimeLockedTokens(address receiver) public view onlyOwner returns (bool canRelease) {
        return _canReleaseTimeLockedTokens(receiver);
    }

    /**
     * @dev Private method for checking if there are some tokens that can be released for receiver.
     */
    function _canReleaseTimeLockedTokens(address receiver) private view returns (bool canRelease) {
        TimeLockedTokenInfo memory timeLockedTokenInfo = timeLockedTokens[receiver];

        require(isValidTimeLockedTokenInfo(timeLockedTokenInfo), 'DecentrSaleContract: There are no time locked tokens for current address');

        return timeLockedTokenInfo.releaseDate <= now;
    }

    /**
     * @dev Sender can request sending tokens directly if there are tokens which are no longer locked by time.
     */
    function receiveTimeLockedTokens() public returns (bool success) {
        return _releaseTimeLockedTokensForAddress(msg.sender);
    }

    /**
     * @dev Owner can request sending tokens directly to receiver if there are tokens which are no longer locked by time.
     */
    function releaseTimeLockedTokensForAddress(address receiver) public onlyOwner returns (bool success) {
        return _releaseTimeLockedTokensForAddress(receiver);
    }

    /**
     * @dev Releasing tokens for receiver if there are tokens which are no longer locked by time.
     */
    function _releaseTimeLockedTokensForAddress(address receiver) private returns (bool success) {

        // Loading info of time locked tokens for the receiver
        TimeLockedTokenInfo memory timeLockedTokenInfo = timeLockedTokens[receiver];

        require(isValidTimeLockedTokenInfo(timeLockedTokenInfo), 'DecentrSaleContract: There are no time locked tokens for address');
        require(timeLockedTokenInfo.releaseDate <= now);

        // Minting tokens for the sender who passed Ether
        DecentrToken.mintToken(receiver, timeLockedTokenInfo.tokensAmount);

        // Emitting event about the tokens release for receiver.
        TimeLockedTokensRelease(receiver, timeLockedTokenInfo.tokensAmount);

        // Cleaning up the record about the time locked tokens after sending tokens to receiver.
        delete timeLockedTokens[receiver];

        // Keeping track of the last block
        _lastBlock = block.number;

        return true;
    }

    /**
    * @dev Owner can remove time locked tokens for receiver.
    */
    function removeTimeLockedTokensForAddress(address receiver) public onlyOwner returns (bool success) {
        TimeLockedTokenInfo memory timeLockedTokenInfo = timeLockedTokens[receiver];

        require(isValidTimeLockedTokenInfo(timeLockedTokenInfo), 'DecentrSaleContract: There are no time locked tokens for receiver address.');

        // Adjusting total minted tokens amount as tokens will not be released ever after removal.
        _totalMinted -= timeLockedTokenInfo.tokensAmount;

        // Cleaning up the record about the time locked tokens after sending tokens to receiver.
        delete timeLockedTokens[receiver];

        return true;
    }

    /**
     * @dev Allows address to get the information about the tokens that will be released for that account.
     */
    function getTimeLockedTokens() public view returns (uint256 tokensAmount, uint releaseDate, bool canBeReleased) {
        return (timeLockedTokens[msg.sender].tokensAmount, timeLockedTokens[msg.sender].releaseDate, timeLockedTokens[msg.sender].releaseDate <= now);
    }

    /**
     * @dev Allows admin to get the information about the tokens that
     * will be released for the address at some certain point of time.
     *
     * modifiers: onlyOwner
     */
    function getTimeLockedTokensForAddress(address _address) public view onlyOwner returns (uint256 tokensAmount, uint releaseDate, uint createdAt, bool canBeReleased) {
        return (timeLockedTokens[_address].tokensAmount, timeLockedTokens[_address].releaseDate, timeLockedTokens[_address].createdAt, timeLockedTokens[msg.sender].releaseDate <= now);
    }

    /**
     * @dev Setup:
     *  - Token to be used
     */
    function setup(address tokenAddress) public pendingInitialization {
        // Loading the Token to work with
        DecentrToken = ERC20DecentrToken(tokenAddress);

        // Setting initialization is complete
        _initializationCompleted = true;
    }

    /**
     * @dev Updates the ETH/COIN rate. Can be controlled only by the owner.
     */
    function setExchangeRate(uint exchangeRate) public onlyOwner whenNotPaused {
        _exchangeRate = exchangeRate;

        // Emitting event about the exchange rate update.
        ExchangeRateUpdate(exchangeRate);
    }

    /**
     * @dev Changes ERC20 Token status to paused.
     */
    function pauseToken() public onlyOwner {
        DecentrToken.pause();
    }

    /**
     * @dev Changes ERC20 Token status to unpaused.
     */
    function unpauseToken() public onlyOwner {
        DecentrToken.unpause();
    }

    /**
     * @dev Closes the trade if opened. Can be controlled only by the owner.
     */
    function closeTrade() public onlyOwner whenNotPaused {
        _pause();

        ContractStateUpdated(true);
    }

    /**
     * @dev Opens the trade if closed. Can be controlled only by the owner.
     */
    function openTrade() public onlyOwner whenPaused {
        _unpause();

        ContractStateUpdated(false);
    }

    /**
     * @dev Returns address of the startBlock.
     */
    function startBlock() public view returns (uint) {
        return _startBlock;
    }

    /**
     * @dev Returns address of the lastBlock.
     */
    function lastBlock() public view returns (uint) {
        return _lastBlock;
    }

    /**
     * @dev Sets ICO wallet to which Eth will be sent in case of minting tokens when contract is not paused.
     */
    function setICOWallet(address payable _wallet) public onlyOwner returns (bool isSet) {
        // Setting up ICO wallet
        ETHWallet = _wallet;

        return true;
    }

    /**
     * @dev Allows publicly to load address of the ICO wallet attached for Ether receiving by contract when contract is not paused and trading is allowed.
     */
    function getICOWallet() public view returns (address icoWallet) {
        return ETHWallet;
    }

    /**
     * @dev Determines if struct is valid. The only workaround to check if struct is not empty.
     */
    function isValidTimeLockedTokenInfo(TimeLockedTokenInfo memory timeLockedTokenInfo) private pure returns (bool isValid) {
        return timeLockedTokenInfo.isEntity;
    }

    /**
     * @dev Checks whether initialization is not completed.
     */
    modifier pendingInitialization() {
        require(!_initializationCompleted, 'DecentrSaleContract: Initialization is already completed.');
        _;
    }

    /**
     * @dev Checks whether initialization is completed.
     */
    modifier initializationCompleted() {
        require(_initializationCompleted, 'DecentrSaleContract: Initialization is not completed.');
        _;
    }

    /**
     * @dev Buy Token function. Accepts Ether. Converts ETH to TOKEN and sends new TOKEN to the sender
     */
    function buyToken() external payable {
        _buyToken();
    }

    /**
     * @dev Should receive Ether when not paused
     */
    function _buyToken() private whenNotPaused initializationCompleted {
        // Sent ether must be above 0
        require(msg.value > 0);

        // Calculating amount of tokens to be sent for a
        uint256 amount = msg.value * _exchangeRate;

        // Calculating total amount of minted tokens
        uint256 total = _totalMinted + amount;

        // Restrict amount of mintable tokens
        require(total <= _maxMintable, 'DecentrSaleContract: Amount of tokens to be minted exceeds the max tokens allowed amount.');

        // Updating total minted tokens amount
        _totalMinted += total;

        // Performing Ether transfer to the ICO account
        ETHWallet.transfer(msg.value);

        // Minting tokens for the sender who passed Ether
        DecentrToken.mintToken(msg.sender, amount);

        // Emitting event about the contribution of a sender into the system by buying the tokens.
        Contribution(msg.sender, amount);

        // Keeping track of the last block
        _lastBlock = block.number;
    }

    /**
     * @dev Default function Accepting Ether. Converts ETH to TOKEN and sends new TOKEN to the sender
     */
    receive() external payable {
        _buyToken();
    }

    /**
     * @dev Fallback function Accepting Ether. Converts ETH to TOKEN and sends new TOKEN to the sender
     */
    fallback() external payable {
        _buyToken();
    }
}
