// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {IUniswapV2Factory, IUniswapV2Pair, IUniswapV2Router02} from "../interfaces/Uniswap.sol";

/// @title OnchainFeed
/// @author Keyrxng
/// @notice OnchainFeed Contract

contract OnchainFeed {

    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    address public baseCurrency;
    
    constructor(
        address _factory,
        address _router,
        address _baseCurrency
        )
    {
        factory = IUniswapV2Factory(_factory);
        router = IUniswapV2Router02(_router);
        baseCurrency = _baseCurrency;
    }

    function setBaseCurrency(address _baseCurrency) internal { baseCurrency = _baseCurrency; }

    /// @notice Returns the latest price of the given token pair
    /// @dev price = 1 baseCurrency = token0
    function getPrice(address _token0, address _token1) external returns (uint256 price) {
        setBaseCurrency(_token0);
        address pairAddress = factory.getPair(_token0, _token1);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint112 r0, uint112 r1, ) = pair.getReserves();
        if (_token0 == baseCurrency) {
            price = 1e18 * r0 / r1;
        } else {
            price = 1e18 * r1 / r0;
        }
        return price;
    }

}
