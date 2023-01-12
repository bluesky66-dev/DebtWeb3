// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title ITreasury
/// @author Keyrxng
/// @notice The Treasury Interface
interface ITreasury {
    function depositEth() external payable;

    function depositToken(address token, uint256 amount) external;

    function depositDW3(uint256 amount) external;

    function depositSDW3(uint256 amount) external;

    function withdrawDW3(uint256 amount) external;

    function withdrawSDW3(uint256 amount) external;

    function releaseEth(address payable to, uint256 amount) external payable;

    function releaseToken(
        address to,
        address token,
        uint256 amount
    ) external;

    function getDW3Balance() external view returns (uint256);

    function getSDW3Balance() external view returns (uint256);

    function getDW3Allowance() external view returns (uint256);

    function getSDW3Allowance() external view returns (uint256);

    function getDW3TotalSupply() external view returns (uint256);

    function getSDW3TotalSupply() external view returns (uint256);
    function pauseProtocol() external;
}
