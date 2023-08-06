// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Account {
    address private _owner;
    uint256 private _totalTokenSupply;
    uint256 private _totalRewards;

    bool internal locked;

    mapping(address => AccountInfo) ownerToAccountInfo;

    struct AccountInfo {
        uint256 balance;
        uint256 createdAt;
        // uint256 lastRewardIndex;
        uint256 rewardTokens;
    }

    constructor() {
        _owner = msg.sender;
    }

    modifier noReentrant() {
        require(!locked, "cannot reenter");
        locked = true;
        _;
        locked = false;
    }

    modifier accountBalanceGreaterThanOrEqualTo(
        address _accountOwner,
        uint256 _amount
    ) {
        require(
            ownerToAccountInfo[_accountOwner].balance >= _amount,
            "Insufficient balance"
        );
        _;
    }

    // rate refers to the amount of tokens equal to 1 ether
    function _getRate() private view returns (uint256) {
        // setting initial rate
        if (_totalTokenSupply == 0) return 1000;
        else {
            uint256 rate = (1 * _totalTokenSupply) / address(this).balance;
            return rate;
        }
    }

    function _getTokensFromEth(
        uint256 ethAmount
    ) private view returns (uint256) {
        return (ethAmount * _getRate());
    }

    function _getEthFromTokens(
        uint256 tokenAmount
    ) private view returns (uint256) {
        return (tokenAmount / _getRate());
    }

    function _updateUserRewards() private {
        if (ownerToAccountInfo[msg.sender].rewardTokens > 0) {
            uint256 balanceWithRewards = (ownerToAccountInfo[msg.sender]
                .rewardTokens * _totalRewards) / 100;
            ownerToAccountInfo[msg.sender].rewardTokens = 0;
            ownerToAccountInfo[msg.sender].balance += balanceWithRewards;
        }
    }

    // TODO: Calculate how much token each person will receive
    function distributeReward() external payable {
        require(msg.sender == _owner);
        uint256 tokens = _getTokensFromEth(msg.value);
        _totalRewards += tokens;
    }

    function deposit() external payable {
        require(
            msg.value > 1 ether,
            "Amount to deposit must be more than 1 ether"
        );

        if (ownerToAccountInfo[msg.sender].createdAt == 0) {
            // save new account
            ownerToAccountInfo[msg.sender] = AccountInfo(
                0,
                block.timestamp,
                msg.value
            );
        }

        uint256 tokenAmount = _getTokensFromEth(msg.value);
        _totalTokenSupply += tokenAmount;
        ownerToAccountInfo[msg.sender].balance += tokenAmount;
    }

    function transfer(
        uint256 _amount,
        address recipient
    )
        external
        noReentrant
        accountBalanceGreaterThanOrEqualTo(msg.sender, _amount)
    {
        ownerToAccountInfo[msg.sender].balance += _amount;
        ownerToAccountInfo[recipient].balance += _amount;
    }

    function burn(
        uint256 _amount
    ) external accountBalanceGreaterThanOrEqualTo(msg.sender, _amount) {
        ownerToAccountInfo[msg.sender].balance -= _amount;
    }

    function withdraw(
        uint256 _amount
    )
        external
        noReentrant
        accountBalanceGreaterThanOrEqualTo(msg.sender, _amount)
    {
        _updateUserRewards();
        uint256 amountToReceive = _getTokensFromEth(_amount);
        ownerToAccountInfo[msg.sender].balance -= amountToReceive;

        (bool success, ) = msg.sender.call{value: amountToReceive}("");
        require(success, "transaction failed");
    }
}
