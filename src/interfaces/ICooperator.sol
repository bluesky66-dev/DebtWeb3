// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title ICooperator
/// @author Keyrxng
/// @notice The Cooperator Interface
interface ICooperator {
    function handleEth(
        address from,
        address payable to,
        uint256 amount
    ) external;

    function depositSDW3(uint256 amount) external;

    function depositDW3(uint256 amount) external;

    function releaseEth(address payable to, uint256 amount) external;

    function releaseToken(
        address token,
        address to,
        uint256 amount
    ) external;

    function receiveEth() external payable;

    function receiveToken(address token, uint256 amount) external;
}
