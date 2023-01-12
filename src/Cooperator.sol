// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import { ITreasury } from "./interfaces/ITreasury.sol";
import { ICore } from "./interfaces/ICore.sol";
import { IGovernor } from "@openzeppelin/contracts/governance/IGovernor.sol";
import {KeeperCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/// @title Cooperator
/// @author Keyrxng
/// @notice A contract the organizes the protocol through authenticated access to the treasury and core contracts
contract Cooperator is KeeperCompatibleInterface {
    uint256 private immutable interval;
    uint256 private lastTimeStamp;

    ITreasury Treasury;
    ICore Core;
    IGovernor Governor;
    address keeper;

    constructor(
        address _treasury,
        address _core,
        address _governor,
        uint256 updateInterval
    ) {
        Treasury = ITreasury(_treasury);
        Core = ICore(_core);
        Governor = IGovernor(_governor);
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
    }

    modifier authed() {
        require(
            msg.sender == address(Core)
                || msg.sender == address(Governor)
                || msg.sender == address(Treasury)
                || msg.sender == keeper, "NotAuthed"
        );
        _;
    }

    struct queueItem {
        address target;
        uint256 value;
        uint256 timestamp;
        bytes payload;
        
    }

    queueItem[] queueItems;
    queueItem[] completedItems;

    enum opState {Pending,Approved,Complete,Rejected}


    mapping(uint256 => queueItem) private queue; // queue of tasks to be perfromed on core contracts
    mapping(uint256 => opState) private queueState; // 0: approved and pending, 1: complete, 2: rejected

    event QueueItemExecuted(bool success, bytes returnData);

    function handleEth(address from, address payable to, uint256 amount) external payable authed {
        if(msg.sender == address(Treasury)){
            Treasury.releaseEth{value: amount}(to, amount);
        }else if(to == address(Treasury)){
            Treasury.depositEth{value: amount}();
        }else if(from == address(Treasury)){
            queueItem memory tempItem = queueItem({
                target: to,
                value: amount,
                timestamp: block.timestamp,
                payload: abi.encodeWithSelector(ITreasury.depositEth.selector)
            });
            queueItems.push(tempItem);
        }else{
            Treasury.depositEth{value: amount}();
        }
    }

    function _executeQueueItem() internal returns(bytes memory) {
        require(queueItems.length > 0, "Nothing in queue");
        queueItem memory item = queueItems[0];
        require(queueState[0] == opState.Approved, "Tx not approved");
        completedItems.push(item);
        delete queueItems[0];
        delete queueState[0];
        (bool ok ,bytes memory mssg ) = item.target.call{value: item.value}(item.payload);
        require(ok, "Tx Failed");
        return (mssg);
    }

    function loadQueueItem(uint256 id) external view authed returns(queueItem memory){
        queueItem memory _queueItem = queueItems[id];
        return (_queueItem);
    }

    function approveQueueItem(uint id) external authed {
        queueItem memory item = queueItems[id];
        queueState[id] = opState.Approved;
    }

    function rejectQueueItem(uint id) external authed {
        require(queueState[id] != opState.Rejected, "Item already rejected");
        queueState[id] = opState.Rejected;
    }


    function updateKeeper(address keeper) external view authed {
        keeper = keeper;
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        virtual
        returns (bool upkeepNeeded, bytes memory performData)
    {
        queueItems.length > 0;
        uint time = queueItems[0].timestamp;
        upkeepNeeded = block.timestamp >= time;
        performData = bytes("");

    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external virtual {
        // add some verification
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Time interval not met");

        lastTimeStamp = block.timestamp;
        bytes memory ret = _executeQueueItem();
        queueItems.pop();
        emit QueueItemExecuted(true, ret);      
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