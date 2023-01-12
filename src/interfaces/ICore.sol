// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title ICore
/// @author Keyrxng
/// @notice The Core Interface
interface ICore {
    function addPaymentToken(address _token) external;

    function calcShares(
        uint256 _amount,
        uint256 _poolId,
        bool _isDW3
    ) external view returns (uint256);

    function createDW3Pool(
        uint256 _totalShares,
        uint256 _totalRewards,
        uint256 _rps
    ) external;

    function createSDW3Pool(
        uint256 _totalShares,
        uint256 _totalRewards,
        uint256 _rps
    ) external;

    function stakeInDW3(
        uint256 _amount,
        address token,
        uint8 _poolId
    ) external;

    function stakeInSWD3(uint256 _amount, uint8 _poolId) external;

    function claimDW3(uint8 _poolId) external;

    function claimSDW3(uint8 _poolId) external;

    function withdrawFromDW3(
        uint256 _amount,
        uint8 _poolId,
        address _token
    ) external;

    function withdrawFromSWD3(uint256 _amount, uint8 _poolId) external;

    function pauseProtocol() external;

    function unpauseProtocol() external;
}
