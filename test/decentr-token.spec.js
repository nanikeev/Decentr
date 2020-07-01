const DecentrSaleContract = artifacts.require('./DecentrSaleContract.sol');
const DecentrToken = artifacts.require('./Decentr.sol');

const BigNumber = web3.utils.BN;

const BigNumberJS = require('bignumber.js');

const should = require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

const truffleAssert = require('truffle-assertions');

contract('DecentrToken', async (accounts) => {

    let tokenManager, decentrToken;

    const [account1, account2, account3, account4, account5] = accounts;

    // Assertion values
    const INIT_TOKENS_AMOUNT = 1e27;

    describe('Decentr Sale Contract driven', () => {

        beforeEach(async () => {
            tokenManager = await DecentrSaleContract.new();
            decentrToken = await DecentrToken.new(tokenManager.address);

            await tokenManager.setup(decentrToken.address);
        });

        describe('on initialization', () => {
            it(`initially token should have certain value of tokens supply for itself which is ${new BigNumberJS(INIT_TOKENS_AMOUNT).toString()}`, async () => {
                const initialTokenTotalSupply = await getTokenBalanceForAddress(decentrToken.address);

                initialTokenTotalSupply.should.equal(new BigNumberJS(INIT_TOKENS_AMOUNT).toString());
            });

            it('initially token should not be paused', async () => {
                (await decentrToken.paused()).should.equal(false);
            });
        });

        describe('pausing should work correctly', () => {

            it('non-minter should be not able to pause token', async () => {
                // Token should be paused
                (await decentrToken.paused()).should.equal(false);

                // Pausing should fail
                await truffleAssert.reverts(decentrToken.pause({from: account1}), 'DecentrToken: Caller is not the Minter.');

                // Token should be paused
                (await decentrToken.paused()).should.equal(false);
            });

            it('minter should be  able to pause token', async () => {
                // Token should be paused
                (await decentrToken.paused()).should.equal(false);

                // Pausing through the minter should be completed
                await tokenManager.pauseToken();

                // Token should be paused
                (await decentrToken.paused()).should.equal(true);
            });

            describe('when token is paused', () => {

                beforeEach(async () => {

                    // Pausing token
                    await tokenManager.pauseToken();

                    // Token should be paused
                    (await decentrToken.paused()).should.equal(true);
                });

                it('transfer of token should be rejected', async () => {
                    await truffleAssert.reverts(decentrToken.transfer(account2, new BigNumberJS(200 * 1e18)), 'Pausable: paused');
                });

                it('token pausing should be rejected', async () => {
                    await await truffleAssert.reverts(tokenManager.pauseToken(), 'Pausable: paused');
                });
            });
        });
    });

    describe('Driven by fake contract address of account', () => {
        beforeEach(async () => {
            decentrToken = await DecentrToken.new(account1);
        });

        describe('pausing should work correctly', () => {

            describe('when token is paused', () => {

                beforeEach(async () => {
                    // Pausing token
                    await decentrToken.pause({from: account1});

                    // Token should be paused
                    (await decentrToken.paused()).should.equal(true);
                });

                it('minting of tokens should be disabled', async () => {
                    await truffleAssert.reverts(decentrToken.mintToken(account2, 200, {from: account1}), 'Pausable: paused');
                });
            });

            describe('when token is not paused', () => {

                beforeEach(async () => {
                    // Token should be paused
                    (await decentrToken.paused()).should.equal(false);
                });

                it('minting of tokens should work properly', async () => {
                    const value = new BigNumberJS(200 * 1e18);

                    await decentrToken.mintToken(account2, value, {from: account1});

                    const tokensForAccount = await getTokenBalanceForAddress(account2);

                    tokensForAccount.should.equal(value.toString());

                    const tokenTotalSupply = new BigNumberJS(await getTokenBalanceForAddress(decentrToken.address)).toString();

                    const initTokensAmount = new BigNumberJS(INIT_TOKENS_AMOUNT);

                    const leftTokens = initTokensAmount.minus(value);

                    tokenTotalSupply.should.equal(leftTokens.toString());
                });

                it('transfer of token should be rejected', async () => {
                    const value = new BigNumberJS(200 * 1e18);

                    // Step 1: Minting tokens for account2
                    await decentrToken.mintToken(account2, value, {from: account1});

                    let tokensOfAccount2 = await getTokenBalanceForAddress(account2);

                    tokensOfAccount2.should.equal(value.toString());

                    // Step 2: Checking account3 has no tokens

                    let tokensOfAccount3 = await getTokenBalanceForAddress(account3);
                    tokensOfAccount3.should.equal('0');

                    const value2 = new BigNumberJS(23 * 1e18);

                    // Step 3: Transferring tokens to account3
                    await decentrToken.transfer(account3, value2, {from: account2});

                    // Step 4: Checking balances of account2 and account3
                    tokensOfAccount2 = await getTokenBalanceForAddress(account2);
                    tokensOfAccount2.should.equal(value.minus(value2).toString());

                    tokensOfAccount3 = await getTokenBalanceForAddress(account3);
                    tokensOfAccount3.should.equal(value2.toString());
                });
            });
        });
    });

    // Utility function for loading tokens balance of the address
    async function getTokenBalanceForAddress(address) {
        return new BigNumberJS((await decentrToken.balanceOf(address)).toString()).toString();
    }
});
