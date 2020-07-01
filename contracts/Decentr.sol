// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";

/**
* @dev Base exchangeable token.
*/
contract Decentr is ERC20, ERC20Pausable {

    /**
     * @dev Address of mintable contract which is a managing contract of a Token.
     */
    address private mintableAddress;

    event TokenMinterUpdated(address minter);

    /**
     * @dev Initialising mintable address and tokens.
     */
    constructor(address saleAddress) public ERC20('Decentr', 'DEC') {
        require(saleAddress != address(0), 'DecentrToken: SaleAddress is not defined.');

        // Setting up decimals
        _setupDecimals(18);

        // Storing address of the mintable contract
        mintableAddress = saleAddress;
        TokenMinterUpdated(mintableAddress);

        // Init Tokens
        initTokens();
    }

    /**
     * @dev Any call to transfer tokens should not do anything in case of the token is not on pause.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Pausable) whenNotPaused {
        // Marker method which adds whenNotPaused modifier usage
    }

    /**
     * @dev Creates all 1 billion tokens. Contract will register 1 billion tokens. Minter or owner will then be able to rearrange contract tokens.
     */
    function initTokens() private {
        // Calculating total supply in tokens.
        // Specify correct amount
        uint256 totalSupply = 10**27;

        // Minting total supply for the contract.
        _mint(address(this), totalSupply);

        _approve(address(this), mintableAddress, totalSupply);
    }

    /**
     * @dev Mints tokens for <receiver> address. Only owner is allowed to mint tokens.
     */
    function mintToken(address receiver, uint256 amount) external onlyMinter whenNotPaused returns (bool success) {
        require(receiver != address(0), 'DecentrToken: Receiver is not defined.');
        require(amount > 0, 'DecentrToken: Amount is not defined.');

        require(balanceOf(address(this)) >= amount, 'DecentrToken: Amount of tokens to be minted exceeds the balance.');

        transferFrom(address(this), receiver, amount);

        return true;
    }

    /**
     * @dev Pauses the token if not paused. Can be controlled only by the minter.
     */
    function pause() external onlyMinter whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the token if paused. Can be controlled only by the minter.
     */
    function unpause() external onlyMinter whenPaused {
        _unpause();
    }

    /**
     * @dev Updates minter of a token. Can be controlled only by the minter.
     */
    function setMiter(address _minter) public onlyMinter whenPaused {
        require(_minter != address(0), 'DecentrToken: Minter should be defined.');

        mintableAddress = _minter;

        TokenMinterUpdated(_minter);
    }

    /**
     * @dev Throws if called by any account other than the miterAccount.
     */
    modifier onlyMinter() {
        require(msg.sender == mintableAddress, 'DecentrToken: Caller is not the Minter.');
        _;
    }
}
