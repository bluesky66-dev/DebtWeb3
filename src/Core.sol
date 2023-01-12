// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DW3} from "./tokens/DW3.sol";
import {SDW3} from "./tokens/SDW3.sol";
import {Pools} from "./Pools.sol";
import {Treasury} from "./Treasury.sol";
import {Cooperator} from "./Cooperator.sol";

import {CoreComponents} from "./lib/CoreComponents.sol";
import {Events} from "./lib/Events.sol";
import {Errors} from "./lib/Errors.sol";

/// @title Core
/// @author Keyrxng
/// @notice The Core contract is the inner mechanics of the protocol which isn't interacted with directly
contract Core is ReentrancyGuard, AccessControl {
    using CoreComponents for CoreComponents.ProtocolTVL;
    using SafeERC20 for DW3;
    using SafeERC20 for SDW3;
    using SafeERC20 for IERC20;

    bytes32 public constant COOP_ROLE = keccak256("COOP_ROLE");
    bytes32 public constant POOL_ROLE = keccak256("POOL_ROLE");
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    mapping(address => CoreComponents.User) public Users;

    bool public paused;

    DW3 dw3;
    SDW3 sdw3;
    Pools pools;
    Treasury treasury;
    Cooperator coop;

    constructor(address _dw3, address _sdw3) {
        dw3 = DW3(_dw3);
        sdw3 = SDW3(_sdw3);

        coop = new Cooperator(address(this), 5 * 60 * 60);
        treasury = new Treasury(address(dw3), address(sdw3), address(this), address(coop));
        pools = new Pools(dw3, sdw3, address(treasury), address(coop));
        
        coop.init(address(treasury), address(pools));
        dw3.init(address(this), address(coop), address(treasury));
        sdw3.init(address(this), address(coop), address(treasury));

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COOP_ROLE, address(coop));
        _setupRole(POOL_ROLE, address(pools));
        _setupRole(TREASURY_ROLE, address(treasury));
    }

    modifier notPaused() {
        if (paused) revert Errors.Paused();
        _;
    }

    function deadlockProtocol() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        pools.pauseProtocol();
        treasury.pauseProtocol();


        paused = true;
    }

    function receiveEther() public payable {
        payable(address(treasury)).transfer(msg.value);
    }

    receive() external payable {
        receiveEther();
    }
}
