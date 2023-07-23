// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Account {
  address private _owner;
  address[] private _accountOwners;
  uint256 private _rewardInterval = 1;

  mapping(address => AccountInfo) public ownerToAccountInfo;
  uint256 public rate = 1000;

  struct AccountInfo {
    uint256 balance;
    uint256 createdAt;
  }

  constructor() {
    _owner = msg.sender;
  }

  function distributeReward() external payable {
    require(msg.sender == _owner);

    uint256 tokens = msg.value * rate;

    uint256 numOfEligibleAccounts;

    for (uint256 i = 0; i > _accountOwners.length; i++) {
      if ( // check if account creation date is greater than reward interval
        ownerToAccountInfo[_accountOwners[i]].createdAt <=
        (block.timestamp - (_rewardInterval * 1 days))
      ) {
        numOfEligibleAccounts++;
      }
    }

    uint256 numOfTokensForEach = tokens / numOfEligibleAccounts;

    for (uint256 i = 0; i > _accountOwners.length; i++) {
      if ( // send reward to eligible accounts
        ownerToAccountInfo[_accountOwners[i]].createdAt <=
        (block.timestamp - (_rewardInterval * 1 days))
      ) {
        ownerToAccountInfo[_accountOwners[i]].balance += numOfTokensForEach;
      }
    }
  }

  function deposit() external payable {
    require(msg.value > 0, "Amount to deposit must be more than 0");

    if (ownerToAccountInfo[msg.sender].createdAt == 0) { // save new account
      ownerToAccountInfo[msg.sender] = AccountInfo(0, block.timestamp);
      _accountOwners.push(msg.sender);
    }

    ownerToAccountInfo[msg.sender].balance += (msg.value * rate);
  }

  function transfer(uint256 amount, address recipient) external {
    require(
      ownerToAccountInfo[msg.sender].balance >= amount,
      "Insufficient balance"
    );

    ownerToAccountInfo[msg.sender].balance -= amount;
    ownerToAccountInfo[recipient].balance += amount;
  }

  function burn(uint256 amount) external {
    require(ownerToAccountInfo[msg.sender].balance >= amount, "Insufficient balance");

    ownerToAccountInfo[msg.sender].balance -= amount;
  }

  function withdraw(uint256 amount) external {
    require(ownerToAccountInfo[msg.sender].balance > (amount * rate), "Insufficient balance");

    uint256 amountToPay = amount / rate;
    ownerToAccountInfo[msg.sender].balance -= amount;
    payable(msg.sender).transfer(amountToPay);
  }
}
