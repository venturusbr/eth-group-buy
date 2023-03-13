const {
  setBalance,
  setStorageAt,
} = require("@nomicfoundation/hardhat-network-helpers");
const {
  loadFixture,
  time,
} = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require("hardhat");
const { BigNumber, Wallet } = require("ethers");
const { assert, expect } = require("chai");
require("dotenv").config();

// loadFixture não permite passagem de parâmetro.
// Issue: https://github.com/NomicFoundation/hardhat/issues/3508

BATCH_LIMIT = 1877845115;
NFT_NAME = "Notebook Dell XYZ";
NFT_SYMBOL = "NOTEDELLXYZ";

async function deployAndCreateBatch() {
  const [nftOwner, addr1, addr2] = await ethers.getSigners();
  const factoryNft = await ethers.getContractFactory("BasicNft");
  const factorySharedEconomy = await ethers.getContractFactory("SharedEconomy");

  const sharedEconomyContract = await factorySharedEconomy
    .connect(nftOwner)
    .deploy();
  const nftContract = await factoryNft
    .connect(nftOwner)
    .deploy(sharedEconomyContract.address, NFT_NAME, NFT_SYMBOL, nftOwner.address);

  const nftAddress = nftContract.address;
  const itemCount = 10;
  const itemPrice = 1;
  const timeLimit = BATCH_LIMIT;

  await sharedEconomyContract
    .connect(nftOwner)
    .createBatch(nftAddress, itemCount, itemPrice, timeLimit);

  return { nftContract, sharedEconomyContract, nftOwner, addr1, addr2 };
}

describe("Testes unitários do contrato SharedEconomy.sol", function () {
  describe("Criação de lote para venda.", function () {
    it("Verifica se um lote é criado corretamente.", async function () {
      const { nftContract, sharedEconomyContract, nftOwner, addr1, addr2 } =
        await loadFixture(deployAndCreateBatch);
      const nftAddress = nftContract.address;
      const itemCount = 10;
      const itemPrice = 1;
      const timeLimit = BATCH_LIMIT;

      const index = 0;
      const [_nftAddress, _itemCount, _itemPrice, _buyCount, _timeLimit] =
        await sharedEconomyContract.getBatchInfo(index);
      assert.equal(_nftAddress, nftAddress);
      assert.equal(_itemCount.toNumber(), itemCount);
      assert.equal(_itemPrice.toNumber(), itemPrice);
      assert.equal(_buyCount.toNumber(), 0);
      assert.equal(_timeLimit.toNumber(), timeLimit);
    });

    it("Verifica que somente o dono da coleção pode criar um lote.", async function () {
      const { nftContract, sharedEconomyContract, nftOwner, addr1, addr2 } =
        await loadFixture(deployAndCreateBatch);
      const nftAddress = nftContract.address;
      const itemCount = 10;
      const itemPrice = 1;
      const timeLimit = BATCH_LIMIT;

      await expect(
        sharedEconomyContract
          .connect(addr1)
          .createBatch(nftAddress, itemCount, itemPrice, timeLimit)
      ).to.be.revertedWith(`NotNFTOwner`);
    });
  });

  describe("Compras.", function () {
    it("Verifica o funcionamento da compra de itens.", async function () {
      const { nftContract, sharedEconomyContract, nftOwner, addr1, addr2 } =
        await loadFixture(deployAndCreateBatch);
      const index = 0;
      const [, itemCount, itemPrice, buyCount] =
        await sharedEconomyContract.getBatchInfo(index);
      const amount = itemCount - buyCount;
      await sharedEconomyContract
        .connect(addr1)
        .buyItemFromBatch(index, amount, { value: itemPrice * amount });
      const contractBalance = await ethers.provider.getBalance(
        sharedEconomyContract.address
      );
      assert.equal(contractBalance, itemPrice * amount);
    });

    it("Verifica que é impossível comprar mais itens do que estão disponíveis.", async function () {
      const { nftContract, sharedEconomyContract, nftOwner, addr1, addr2 } =
        await loadFixture(deployAndCreateBatch);
      const index = 0;
      const [, itemCount, itemPrice, buyCount] =
        await sharedEconomyContract.getBatchInfo(index);
      const amount = itemCount - buyCount + 1;
      await expect(
        sharedEconomyContract
          .connect(addr1)
          .buyItemFromBatch(index, amount, { value: itemPrice * amount })
      ).to.be.revertedWith(`BatchCompleted`);
    });

    it("Verifica que é impossível comprar após a expiração do lote.", async function () {
      const { nftContract, sharedEconomyContract, nftOwner, addr1, addr2 } =
        await loadFixture(deployAndCreateBatch);
      await time.increaseTo(BATCH_LIMIT + 1);
      const index = 0;
      const [, itemCount, itemPrice, buyCount] =
        await sharedEconomyContract.getBatchInfo(index);
      const amount = itemCount - buyCount;
      await expect(
        sharedEconomyContract
          .connect(addr1)
          .buyItemFromBatch(index, amount, { value: itemPrice * amount })
      ).to.be.revertedWith(`BatchExpired`);
    });

    it("Verifica que é impossível comprar pagando menos que o preço definido.", async function () {
      const { nftContract, sharedEconomyContract, nftOwner, addr1, addr2 } =
        await loadFixture(deployAndCreateBatch);
      const index = 0;
      const [, itemCount, itemPrice, buyCount] =
        await sharedEconomyContract.getBatchInfo(index);
      const amount = itemCount - buyCount;
      await expect(
        sharedEconomyContract
          .connect(addr1)
          .buyItemFromBatch(index, amount, { value: itemPrice * amount - 1 })
      ).to.be.revertedWith(`InsufficientValue`);
    });
  });

  describe("Cancelamento.", function () {
    it("Verifica o cancelamento dentro do prazo.", async function () {
      const { nftContract, sharedEconomyContract, nftOwner, addr1, addr2 } =
        await loadFixture(deployAndCreateBatch);
      const index = 0;
      const [, itemCount, itemPrice, buyCount] =
        await sharedEconomyContract.getBatchInfo(index);
      const amount = itemCount - buyCount;
      await sharedEconomyContract
        .connect(addr1)
        .buyItemFromBatch(index, amount, { value: itemPrice * amount });
      await sharedEconomyContract.connect(addr1).cancelPurchase(index, amount);

      await sharedEconomyContract
        .connect(addr1)
        .buyItemFromBatch(index, amount, { value: itemPrice * amount });
      await time.increaseTo(BATCH_LIMIT + 1);
      await expect(
        sharedEconomyContract.connect(addr1).cancelPurchase(index, amount)
      ).to.be.revertedWith(`BatchExpired`);
    });

    it("Verifica que é impossível cancelar mais do que comprou.", async function () {
      const { nftContract, sharedEconomyContract, nftOwner, addr1, addr2 } =
        await loadFixture(deployAndCreateBatch);
      const index = 0;
      const [, itemCount, itemPrice, buyCount] =
        await sharedEconomyContract.getBatchInfo(index);
      const amount = itemCount - buyCount;
      await sharedEconomyContract
        .connect(addr1)
        .buyItemFromBatch(index, amount, { value: itemPrice * amount });
      await expect(
        sharedEconomyContract.connect(addr1).cancelPurchase(index, amount + 1)
      ).to.be.revertedWith(`CancelAmountTooLarge`);
    });
  });

  describe("Resgate.", function () {
    it("Verifica o resgate de itens após compra e finalização do lote.", async function () {
      const { nftContract, sharedEconomyContract, nftOwner, addr1, addr2 } =
        await loadFixture(deployAndCreateBatch);
      const index = 0;
      const [, itemCount, itemPrice, buyCount] =
        await sharedEconomyContract.getBatchInfo(index);
      const amount = itemCount - buyCount;
      await sharedEconomyContract
        .connect(addr1)
        .buyItemFromBatch(index, amount, { value: itemPrice * amount });
      await time.increaseTo(BATCH_LIMIT + 1);
      await sharedEconomyContract.connect(addr1).claimItems(index);
      const claimedItems = await nftContract.balanceOf(addr1.address);
      assert.equal(claimedItems, amount);
    });

    it("Verifica que é impossível resgatar depois de cancelar a compra.", async function () {
      const { nftContract, sharedEconomyContract, nftOwner, addr1, addr2 } =
        await loadFixture(deployAndCreateBatch);
      const index = 0;
      const [, itemCount, itemPrice, buyCount] =
        await sharedEconomyContract.getBatchInfo(index);
      const amount = itemCount - buyCount;
      await sharedEconomyContract
        .connect(addr1)
        .buyItemFromBatch(index, amount, { value: itemPrice * amount });
      await sharedEconomyContract.connect(addr1).cancelPurchase(index, amount);
      await time.increaseTo(BATCH_LIMIT + 1);
      await sharedEconomyContract.connect(addr1).claimItems(index);
      const claimedItems = await nftContract.balanceOf(addr1.address);
      assert.equal(claimedItems, 0);
    });

    it("Verifica que é impossível resgatar mais de uma vez.", async function () {
      const { nftContract, sharedEconomyContract, nftOwner, addr1, addr2 } =
        await loadFixture(deployAndCreateBatch);
      const index = 0;
      const [, itemCount, itemPrice, buyCount] =
        await sharedEconomyContract.getBatchInfo(index);
      const amount = itemCount - buyCount;
      await sharedEconomyContract
        .connect(addr1)
        .buyItemFromBatch(index, amount, { value: itemPrice * amount });
      await time.increaseTo(BATCH_LIMIT + 1);
      await sharedEconomyContract.connect(addr1).claimItems(index);
      const claimedItems = await nftContract.balanceOf(addr1.address);
      assert.equal(claimedItems, amount);
      await expect(
        sharedEconomyContract.connect(addr1).claimItems(index)
      ).to.be.revertedWith(`AlreadyClaimed`);
    });
  });
});
