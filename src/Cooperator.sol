// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { ITreasury } from "./interfaces/ITreasury.sol";
import { ICore } from "./interfaces/ICore.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";

/// @title Cooperator
/// @author Keyrxng
/// @notice A contract the organizes the protocol through authenticated access to the treasury and core contracts
contract Cooperator {

    ITreasury Treasury;
    ICore Core;
    IGovernor Governer;

    constructor(
        address _treasury,
        address _core,
        address _governor
    ) {
        Treasury = ITreasury(_treasury);
        Core = ICore(_core);
        Governer = IGovernor(_governor);
    }

    modifier authed() {
        require(
            msg.sender == address(Core)
                || msg.sender == address(Governer)
                || msg.sender == address(Treasury), "NotAuthed"
        );
        _;
    }


    function handleEth(address from, address payable to, uint256 amount) external payable authed {
        if(from == address(Treasury)){
            Treasury.releaseEth{value: amount}(to, amount);
        }else if(to == address(Core)){
            Core.receiveEth{value: amount}();
        }else if(from == address(Governer)){
            _;
        }else{
            Treasury.receiveEth{value: amount}();
        }
    }
      
      
        // Treasury.depositEth{value: amount}();
        // (bool success,) = to.call{value: amount}("");
        // require(success, "EthTransferFailed");
    }

    function depositSDW3(uint256 amount) external authed {

    }

    function depositDW3(uint256 amount) external authed {

    }

    function releaseEth(address payable to, uint256 amount) external authed {

    }

    function releaseToken(address token, address to, uint256 amount) external authed {

    }

    function receiveEth() external payable authed {

    }

    function receiveToken(address token, uint256 amount) external authed{

    }
}