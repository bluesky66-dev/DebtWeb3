// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Keepers
/// @author Keyrxng
/// @notice The Keepers contract 
contract KeepersPriceFeed {
    AggregatorV3Interface internal immutable priceFeed;

    constructor(address _feed) {
        priceFeed = AggregatorV3Interface(
            _feed
        );
    }

    
    /**
     * @notice Returns the latest price
     *
     * @return latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /* uint80 roundID */
            int256 price,
            ,
            ,

        ) = /* uint256 startedAt */
            /* uint256 timeStamp */
            /* uint80 answeredInRound */
            priceFeed.latestRoundData();
        return price;
    }

    /**
     * @notice Returns the Price Feed address
     *
     * @return Price Feed address
     */
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }


}