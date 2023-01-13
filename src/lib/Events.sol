// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Events
/// @notice Events are dispatched from various parts of the application
library Events {
    event StakeInDW3(address indexed user, uint256 indexed amount);

    event StakeInSWD3(address indexed user, uint256 indexed amount);

    event WithdrawFromDW3(address indexed user, uint256 amount);

    event WithdrawFromSWD3(address indexed user, uint256 amount);

    event ClaimDW3(address who, uint256 amount);

    event ClaimSDW3(address who, uint256 amount);

    event DW3PoolCreated(uint256 poolId, uint256 rps, uint256 totalRewards);

    event SDW3PoolCreated(uint256 poolId, uint256 rps, uint256 totalRewards);

    event ReleasedEth(address indexed to, uint256 indexed amount);

    event ReceivedEth(address indexed from, uint256 indexed amount);
    event TokenisedLOD(address indexed from, uint256 indexed id, uint256 debtDuration, uint256 indexed amount);

    event Paused();

    event Unpaused();

    event Staked(address indexed who, uint256 pool, uint256 amount);

    event Unstaked(address indexed who, uint256 pool, uint256 amount);

    event Claimed(address indexed who, uint256 pool, uint256 amount);

    event ReceiveEther(
        address indexed sender,
        uint256 indexed amount,
        uint256 indexed timestamp
    );

    event ReleasedToken(
        address indexed to,
        address indexed token,
        uint256 indexed amount
    );

    event ReceivedToken(
        address indexed from,
        address indexed token,
        uint256 indexed amount
    );
}
