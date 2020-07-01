const DecentrSaleContract = artifacts.require('./DecentrSaleContract.sol');
const DecentrToken = artifacts.require('./Decentr.sol');

const BigNumber = web3.utils.BN;

const BigNumberJS = require('bignumber.js');

const should = require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

contract('DecentrSaleContract', async (accounts) => {

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

        it(`initially token should have certain value of tokens supply for itself which is ${new BigNumberJS(INIT_TOKENS_AMOUNT).toString()}`, async () => {
            const initialTokenTotalSupply = await getTokenBalanceForAddress(decentrToken.address);

            initialTokenTotalSupply.should.equal(new BigNumberJS(INIT_TOKENS_AMOUNT).toString());
        });

        it('should be initialized properly', async () => {

            // Contract should be paused
            (await tokenManager.paused()).should.equal(true);
        });

        it('should create tokens which are locked and will be unlocked after some specified time. Release should be available after some time only.', async () => {

            const value = new BigNumberJS(5000 * 1e18);

            // Registering time locked tokens for account2
            await tokenManager.registerTimeLockedTokens(account2, value, Math.trunc(new Date().getTime() / 1000) + 2); // +2 seconds

            // Checking if account2 can receive tokens
            (await tokenManager.canReceiveTimeLockedTokens({from: account2})).should.equal(false);

            // Checking by contract owner if account2 can receive tokens
            (await tokenManager.canReleaseTimeLockedTokens(account2)).should.equal(false);

            const value2 = new BigNumberJS(60000 * 1e18);

            // Registering time locked tokens for account3
            await tokenManager.registerTimeLockedTokens(account3, value2, Math.trunc(new Date().getTime() / 1000));

            // Checking account3 can receive tokens
            (await tokenManager.canReceiveTimeLockedTokens({from: account3})).should.equal(true);

            // Checking by contract owner if account3 can receive tokens
            (await tokenManager.canReleaseTimeLockedTokens(account3)).should.equal(true);

            // When time has gone we still need to be sure no tokens automatically assigned
            (await getTokenBalanceForAddress(account3)).should.equal('0');

            // Triggering receiving tokens
            await tokenManager.receiveTimeLockedTokens({from: account3});

            const spentTokens = new BigNumberJS((60000 * 1e18).toString());

            // Making sure account3 has tokens
            (await getTokenBalanceForAddress(account3)).should.equal(spentTokens.toString());

            // Checking that total supply of tokens was adjusted accordingly to send tokens
            const tokenTotalSupply = new BigNumberJS(await getTokenBalanceForAddress(decentrToken.address));

            const initTokensAmount = new BigNumberJS(INIT_TOKENS_AMOUNT);

            const leftTokens = initTokensAmount.minus(spentTokens);

            tokenTotalSupply.eq(leftTokens).should.equal(true);
        });
    });

    // Utility function for loading tokens balance of the address
    async function getTokenBalanceForAddress(address) {
        return new BigNumberJS((await decentrToken.balanceOf(address)).toString()).toString();
    }
});
