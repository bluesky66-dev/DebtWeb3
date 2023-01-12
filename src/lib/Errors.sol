// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Errors
/// @notice Errors are dispatched from various parts of the application
library Errors {
    error Paused();
    error TokenNotSupported();
    error InsufficientBalance(uint256 requested, uint256 available);
    error PoolNotActiveYet(uint256 poolId, uint256 whenActive);
    error InsufficientRewardBalance(uint256 requested, uint256 available);
    

}
