const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiSend", function () {
  let multiSend;
  let owner, addr1, addr2, addr3, addr4;

  // Deploy a fresh contract before each test for isolation
  beforeEach(async function () {
    [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

    const MultiSend = await ethers.getContractFactory("MultiSend");
    multiSend = await MultiSend.deploy();
    await multiSend.waitForDeployment();
  });

  it("should set the deployer as owner", async function () {
    expect(await multiSend.owner()).to.equal(owner.address);
  });

  it("should distribute Ether equally among recipients", async function () {
    const recipients = [addr1.address, addr2.address, addr3.address, addr4.address];
    const sendValue = ethers.parseEther("0.04"); // 0.01 ETH each
    const expectedShare = ethers.parseEther("0.01");

    const balancesBefore = await Promise.all(
      recipients.map((addr) => ethers.provider.getBalance(addr))
    );

    await multiSend.multiSend(recipients, { value: sendValue });

    const balancesAfter = await Promise.all(
      recipients.map((addr) => ethers.provider.getBalance(addr))
    );

    for (let i = 0; i < recipients.length; i++) {
      expect(balancesAfter[i] - balancesBefore[i]).to.equal(expectedShare);
    }

    // Contract should hold zero leftover balance for an evenly divisible amount
    expect(await multiSend.getContractBalance()).to.equal(0);
  });

  it("should revert on empty recipients array", async function () {
    await expect(
      multiSend.multiSend([], { value: ethers.parseEther("0.01") })
    ).to.be.revertedWith("MultiSend: recipients array is empty");
  });

  it("should revert when no Ether is sent", async function () {
    await expect(
      multiSend.multiSend([addr1.address, addr2.address], { value: 0 })
    ).to.be.revertedWith("MultiSend: no Ether sent");
  });

  it("should revert when Ether amount is too small to split", async function () {
    // 4 wei split among 5 recipients => 0 per recipient
    await expect(
      multiSend.multiSend(
        [addr1.address, addr2.address, addr3.address, addr4.address, owner.address],
        { value: 4n }
      )
    ).to.be.revertedWith("MultiSend: Ether amount too small to split among recipients");
  });

  it("should revert if a recipient is the zero address", async function () {
    await expect(
      multiSend.multiSend(
        [addr1.address, ethers.ZeroAddress],
        { value: ethers.parseEther("0.02") }
      )
    ).to.be.revertedWith("MultiSend: recipient is the zero address");
  });

  it("should leave dust in contract for uneven division and allow owner to withdraw it", async function () {
    const recipients = [addr1.address, addr2.address, addr3.address];
    await multiSend.multiSend(recipients, { value: 10n }); // 3 wei each, 1 wei dust

    expect(await multiSend.getContractBalance()).to.equal(1n);

    await expect(multiSend.withdrawDust()).to.not.be.reverted;
    expect(await multiSend.getContractBalance()).to.equal(0n);
  });

  it("should revert dust withdrawal from non-owner", async function () {
    await expect(
      multiSend.connect(addr1).withdrawDust()
    ).to.be.revertedWith("MultiSend: caller is not the owner");
  });

  it("should reject direct Ether transfers", async function () {
    await expect(
      owner.sendTransaction({ to: await multiSend.getAddress(), value: ethers.parseEther("0.01") })
    ).to.be.revertedWith("MultiSend: send Ether via multiSend(), not direct transfer");
  });

  it("should revert the entire batch if one transfer fails", async function () {
    // Deploy a helper contract that rejects all incoming Ether
    const RevertingReceiver = await ethers.getContractFactory("RevertingReceiver");
    const reverter = await RevertingReceiver.deploy();
    await reverter.waitForDeployment();

    const recipients = [addr1.address, await reverter.getAddress()];

    await expect(
      multiSend.multiSend(recipients, { value: ethers.parseEther("0.02") })
    ).to.be.revertedWith("MultiSend: transfer to recipient failed");
  });
});
