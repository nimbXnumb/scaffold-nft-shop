import { expect } from "chai";
import { ethers } from "hardhat";
import { YourContract } from "../typechain-types";

describe("YourContract", function () {
  let yourContract: YourContract;
  let owner: any;
  let bidder1: any;
  let bidder2: any;

  before(async () => {
    [owner, bidder1, bidder2] = await ethers.getSigners();
    const yourContractFactory = await ethers.getContractFactory("YourContract");
    yourContract = (await yourContractFactory.deploy(owner.address)) as YourContract;
    await yourContract.waitForDeployment();
  });

  describe("Auctions", function () {
    it("Should create an auction successfully", async function () {
      const tokenId = 1;
      const duration = 100;
      const minIncrement = 10;

      await yourContract.createAuction(tokenId, duration, minIncrement);
      const auction = await yourContract.auctions(1);

      expect(auction.tokenId).to.equal(tokenId);
      expect(auction.endTime).to.be.greaterThan(0);
      expect(auction.minIncrement).to.equal(minIncrement);
      expect(auction.active).to.be.true;
    });

    it("Should fail to place a bid below the minimum increment", async function () {
      const bidAmount = 5;

      await expect(yourContract.connect(bidder1).placeBid(1, { value: bidAmount })).to.be.revertedWith(
        "Bid is too low",
      );
    });

    it("Should update the highest bidder and bid when a new valid bid is placed", async function () {
      const bidAmount = 20;
      await yourContract.connect(bidder1).placeBid(1, { value: bidAmount });
      const auction = await yourContract.auctions(1);

      expect(auction.highestBidder).to.equal(bidder1.address);
      expect(auction.highestBid).to.equal(bidAmount);
    });

    it("Should refund the previous highest bidder on a new higher bid", async function () {
      const initialBalance = await ethers.provider.getBalance(bidder1.address);
      const newBidAmount = 50;

      await yourContract.connect(bidder2).placeBid(1, { value: newBidAmount });
      const auction = await yourContract.auctions(1);

      const finalBalance = await ethers.provider.getBalance(bidder1.address);

      expect(auction.highestBidder).to.equal(bidder2.address);
      expect(auction.highestBid).to.equal(newBidAmount);
      expect(finalBalance).to.be.closeTo(initialBalance, 20);
    });

    it("Should end the auction successfully and transfer NFT to the winner", async function () {
      await ethers.provider.send("evm_increaseTime", [100]);
      await ethers.provider.send("evm_mine", []);

      await yourContract.connect(owner).endAuction(1);
      const auction = await yourContract.auctions(1);

      const userNFTs = await yourContract.getUserNFTs(bidder2.address);

      expect(auction.active).to.be.false;
      expect(userNFTs.map(id => id.toString())).to.include("1");
    });

    it("Should fail to place a bid after the auction has ended", async function () {
      const bidAmount = 100;

      await expect(yourContract.connect(bidder1).placeBid(1, { value: bidAmount })).to.be.revertedWith(
        "Auction has ended",
      );
    });

    it("Should fail to end the auction if not owner and before time has elapsed", async function () {
      const tokenId = 2;
      const duration = 100;
      const minIncrement = 10;

      await yourContract.createAuction(tokenId, duration, minIncrement);

      await expect(yourContract.connect(bidder1).endAuction(2)).to.be.revertedWith("Auction is still ongoing");
    });
  });

  describe("User NFTs", function () {
    it("Should return an empty list for a user with no NFTs", async function () {
      const userNFTs = await yourContract.getUserNFTs(bidder1.address);
      expect(userNFTs).to.be.empty;
    });

    it("Should return the correct list of NFTs for a user", async function () {
      const userNFTs = await yourContract.getUserNFTs(bidder2.address);
      expect(userNFTs.map(id => id.toString())).to.include("1");
    });
  });
});
