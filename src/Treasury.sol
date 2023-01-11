// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";

/// @title Treasury
/// @author Keyrxng
/// @notice The Treasury contract manages the DebtWeb3 protocol treasury
contract Treasury is ReentrancyGuard, AccessControl {

    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    IERC20 public DW3;
    IERC20 public SDW3;

    constructor(IERC20 _DW3, IERC20 _SDW3) {
        DW3 = _DW3;
        SDW3 = _SDW3;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TREASURY_ROLE, msg.sender);
    }

    function depositDW3(uint256 amount) public {
        DW3.transferFrom(msg.sender, address(this), amount);
    }

    function depositSDW3(uint256 amount) public {
        SDW3.transferFrom(msg.sender, address(this), amount);
    }

    function withdrawDW3(uint256 amount) public {
        DW3.transfer(msg.sender, amount);
    }

    function withdrawSDW3(uint256 amount) public {
        SDW3.transfer(msg.sender, amount);
    }

    function getDW3Balance() public view returns (uint256) {
        return DW3.balanceOf(address(this));
    }

    function getSDW3Balance() public view returns (uint256) {
        return SDW3.balanceOf(address(this));
    }

    function getDW3Allowance() public view returns (uint256) {
        return DW3.allowance(msg.sender, address(this));
    }

    function getSDW3Allowance() public view returns (uint256) {
        return SDW3.allowance(msg.sender, address(this));
    }

    function getDW3TotalSupply() public view returns (uint256) {
        return DW3.totalSupply();
    }

    function getSDW3TotalSupply() public view returns (uint256) {
        return SDW3.totalSupply();
    }


}