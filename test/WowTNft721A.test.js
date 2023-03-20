const { expect } = require('chai');
const { upgrades } = require('hardhat');
const hre = require('hardhat');
const { SignerWithAddress } = require('@nomiclabs/hardhat-ethers/signers.js');
const { Contract } = require('ethers');

describe('WowTNft721A', function () {
  const name = 'wowT721';
  const symbol = 'wowT';
  const maxSupply = 10;
  const feeAddress = '0x26BA546b581f859BFeE6821958097E8bA1C24444';
  const contractURI =
    'https://wowtalkiesdevbucket.s3.ap-south-1.amazonaws.com/collections/wowtalkiesgenesis/chainlink.json';
  const preRevealUri =
    'https://wowtalkiestestbucket.s3.ap-south-1.amazonaws.com/collections/GenerativeNfts/preRevealUri.json';
  const tokenPrice = '1000000000000000000';
  const tokenURI = 'https://nfttest.wowtalkies.com:3200/v1/token/metadata/';
  const subscriptionId = 10484;
  const vrfCoordinator = '0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D';
  const keyHash =
    '0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15';

  let contract = Contract;
  let owner = SignerWithAddress;
  let otherUser = SignerWithAddress;

  beforeEach(async function () {
    const Contract = await hre.ethers.getContractFactory('WowTNft721A');

    const [_owner, _otherUser] = await hre.ethers.getSigners();
    owner = _owner;
    otherUser = _otherUser;

    contract = await upgrades.deployProxy(Contract, [
      name,
      symbol,
      contractURI,
      preRevealUri,
      tokenPrice,
      maxSupply,
      feeAddress,
      subscriptionId,
      vrfCoordinator,
      keyHash,
    ]);
    await contract.deployed();
  });

  describe('setters', function () {
    describe('owner', function () {
      it('should successfully set and retrieve contractURI', async () => {
        const newURI = 'ipfs://testuri.json';
        await contract.setContractUri(newURI);
        await expect(await contract.contractUri()).to.equal(newURI);
      });
      it('should successfully set and retrieve baseURI', async () => {
        const newURI = 'ipfs://testuri';
        await contract.setPreRevealURI(newURI);
        await expect(await contract.preRevealURI()).to.equal(newURI);
      });
      it('should successfully set and retrieve maxSupply', async () => {
        const newSupply = 33;
        await contract.setMaxSupply(newSupply);
        await expect(await contract.maxSupply()).to.equal(newSupply);
      });
      it('should successfully set and retrieve whiteListAddress', async () => {
        const whiteListAddresses = [
          '0xF39FE9013f19c9B2C3129340C7Fc86F195C1842B',
          '0x96FFb451863ace1fE67F2dfc87A45e5298fcc01e',
        ];
        await contract.setWhitelistAddress(whiteListAddresses, 2, 50000000, 20);
        await expect(
          await contract.findAddressInWhitelist(
            '0xF39FE9013f19c9B2C3129340C7Fc86F195C1842B'
          )
        ).to.equal(true);
      });
      it('should successfully set and retrieve whiteListTokenPrice', async () => {
        const newWhiteListPrice = '25000000000000000';
        await contract.setWhitelistPrice(newWhiteListPrice);
        const newPrice = await contract.whitelists();
        await expect(newPrice[0]).to.equal(newWhiteListPrice);
      });
      it('should successfully set and retrieve whiteList maxSupply', async () => {
        const newWhiteListSupply = 50;
        await contract.setMaxWhitelistSupply(newWhiteListSupply);
        const newSupply = await contract.whitelists();
        await expect(newSupply[3]).to.equal(newWhiteListSupply);
      });
      it('should successfully set and retrieve allowListAddress', async () => {
        const whiteListAddresses = [
          '0xF39FE9013f19c9B2C3129340C7Fc86F195C1842B',
          '0x96FFb451863ace1fE67F2dfc87A45e5298fcc01e',
        ];
        await contract.setAllowlistAddress(whiteListAddresses, 2, 50000000, 20);
        await expect(
          await contract.findAddressInAllowlist(
            '0xF39FE9013f19c9B2C3129340C7Fc86F195C1842B'
          )
        ).to.equal(true);
      });
      it('should successfully set and retrieve allowListTokenPrice', async () => {
        const newAllowListPrice = '25000000000000000';
        await contract.setAllowlistPrice(newAllowListPrice);
        const newPrice = await contract.allowlists();
        await expect(newPrice[0]).to.equal(newAllowListPrice);
      });
      it('should successfully set and retrieve whiteList maxSupply', async () => {
        const newAllowListSupply = 50;
        await contract.setMaxAllowlistSupply(newAllowListSupply);
        const newSupply = await contract.allowlists();
        await expect(newSupply[3]).to.equal(newAllowListSupply);
      });
      it('should successfully set and retrieve tokenPrice', async () => {
        const newTokenPrice = '30000000000000000';
        await contract.setTokenPrice(newTokenPrice);
        await expect(await contract.tokenPrice()).to.equal(newTokenPrice);
      });
      it('should successfully set and retrieve feeAddress', async () => {
        const newFeeAddress = '0x96FFb451863ace1fE67F2dfc87A45e5298fcc01e';
        await contract.setFeeAddress(newFeeAddress);
        await expect(await contract.feeAddress()).to.equal(newFeeAddress);
      });
      it('should successfully set and retrieve pauseToken', async () => {
        await contract.setSaleStatus(0);
        await expect(await contract.saleStatus()).to.equal(0);
      });
      // it('should successfully call setReveal if the caller is owner', async () => {
      //   await contract.startReveal('https://testuri');
      //   await expect(await contract.postRevealBaseURI()).to.equal(
      //     'https://testuri'
      //   );
      // });
    });
    describe('non-owner', function () {
      it('should not be able to setPreRevealURI', async () => {
        await expect(
          contract.connect(otherUser).setPreRevealURI('ipfs://123/')
        ).to.be.revertedWith('Ownable: caller is not the owner');
      });
      it('should not be able to setContractURI', async () => {
        await expect(
          contract.connect(otherUser).setContractUri('ipfs://123/.json')
        ).to.be.revertedWith('Ownable: caller is not the owner');
      });
      it('should not be able to setMaxSupply', async () => {
        await expect(
          contract.connect(otherUser).setMaxSupply(333)
        ).to.be.revertedWith('Ownable: caller is not the owner');
      });
      it('should not be able to setWhiteListAddress', async () => {
        const whiteListAddresses = [
          '0xF39FE9013f19c9B2C3129340C7Fc86F195C1842B',
          '0x96FFb451863ace1fE67F2dfc87A45e5298fcc01e',
        ];
        // await contract.setWhitelistAddress(whiteListAddresses, true);
        await expect(
          contract
            .connect(otherUser)
            .setWhitelistAddress(whiteListAddresses, 2, 50000000, 20)
        ).to.be.revertedWith('Ownable: caller is not the owner');
      });
      it('should not be able to setTokenPrice', async () => {
        await expect(
          contract.connect(otherUser).setTokenPrice(1000000)
        ).to.be.revertedWith('Ownable: caller is not the owner');
      });
      it('should not be able to setWhiteListTokenPrice', async () => {
        await expect(
          contract.connect(otherUser).setWhitelistPrice('25000000000000000')
        ).to.be.revertedWith('Ownable: caller is not the owner');
      });
      it('should not be able to setFeeAddress', async () => {
        await expect(
          contract
            .connect(otherUser)
            .setFeeAddress('0x96FFb451863ace1fE67F2dfc87A45e5298fcc01e')
        ).to.be.revertedWith('Ownable: caller is not the owner');
      });
      it('should not be able to setPauseToken', async () => {
        await expect(
          contract.connect(otherUser).setSaleStatus(0)
        ).to.be.revertedWith('Ownable: caller is not the owner');
      });
    });
  });
  describe('buyToken', function () {
    it('should successfully whitelist buyToken if caller is whitelisted', async () => {
      await contract.setSaleStatus(1);
      await contract.setWhitelistAddress(
        ['0x70997970C51812dc3A010C7d01b50e0d17dc79C8'],
        6,
        50000000000000,
        20
      );
      await contract.connect(otherUser).buyToken(6, {
        from: otherUser.address,
        value: hre.ethers.utils.parseEther('0.0003'),
      });
      await expect(await contract.totalMinted()).to.be.equal(6);
    });
    it('should successfully allowlist buyToken if caller is allowlisted', async () => {
      await contract.setSaleStatus(2);
      await contract.setAllowlistAddress(
        ['0x70997970C51812dc3A010C7d01b50e0d17dc79C8'],
        6,
        50000000000000,
        20
      );
      await contract.connect(otherUser).buyToken(4, {
        from: otherUser.address,
        value: hre.ethers.utils.parseEther('0.0002'),
      });
      await expect(await contract.totalMinted()).to.be.equal(4);
    });
    it('should successfully public buyToken if caller is public', async () => {
      await contract.setSaleStatus(3);
      await contract.connect(otherUser).buyToken(6, {
        from: otherUser.address,
        value: hre.ethers.utils.parseEther('6.0'),
      });
      await expect(await contract.exists(1)).to.be.equal(true);
    });
    it('should not buyToken if token is paused', async () => {
      await contract.setSaleStatus(0);
      await expect(
        contract.connect(otherUser).buyToken(16, {
          from: otherUser.address,
          value: hre.ethers.utils.parseEther('160.0'),
        })
      ).to.be.revertedWith('token is paused');
    });
    it('should not buyToken if value is below the minimum tokenPrice', async function () {
      await contract.setTokenPrice(hre.ethers.utils.parseEther('10.0'));
      await expect(
        contract.buyToken(1, {
          from: owner.address,
          value: hre.ethers.utils.parseEther('9.0'),
        })
      ).to.be.revertedWith('Not enough eth sent');
    });
    it('should not buyToken if amount is greater than max supply', async () => {
      await contract.setMaxSupply(5);
      await contract.setTokenPrice(hre.ethers.utils.parseEther('10.0'));
      await expect(
        contract.connect(otherUser).buyToken(16, {
          from: otherUser.address,
          value: hre.ethers.utils.parseEther('160.0'),
        })
      ).to.be.revertedWith('Maximum supply reached');
    });
    it('should not whitelist buyToken if caller is non whitelisted', async () => {
      await contract.setSaleStatus(1);
      await expect(
        contract.connect(otherUser).buyToken(5, {
          from: otherUser.address,
          value: hre.ethers.utils.parseEther('5.0'),
        })
      ).to.be.revertedWith('You are not whitelisted');
    });
    it('should not allowlist buyToken if caller is non allowlisted', async () => {
      await contract.setSaleStatus(2);
      await expect(
        contract.connect(otherUser).buyToken(5, {
          from: otherUser.address,
          value: hre.ethers.utils.parseEther('5.0'),
        })
      ).to.be.revertedWith('You are not allowlisted');
    });
  });
});
