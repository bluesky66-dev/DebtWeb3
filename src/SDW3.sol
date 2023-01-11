// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title SDW3
/// @author Keyrxng
/// @notice The SDW3 contract is the DebtWeb3 stablecoin
/// @dev The SDW3 contract is the DebtWeb3 stablecoin, algorithmically pegged using protocol TVL & LiquidDebt Levels
contract SDW3 is ERC20, ERC20Burnable {

    constructor() ERC20("StableDW3", "SDW3") {
        _mint(msg.sender, 1000000000000000000000000);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }

}