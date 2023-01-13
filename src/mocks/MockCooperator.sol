// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ITreasury} from "../interfaces/ITreasury.sol";
import {ICore} from "../interfaces/ICore.sol";
import {IPools} from "../interfaces/IPools.sol";

import {Events} from "../lib/Events.sol";
import {Errors} from "../lib/Errors.sol";

import {KeeperCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/// @title Cooperator
/// @author Keyrxng
/// @notice A contract the organizes the protocol through authenticated access to the treasury and core contracts
contract Cooperator is KeeperCompatibleInterface {
    uint256 private immutable interval;
    uint256 private lastTimeStamp;
    uint256 private immutable queueInterval;

    ITreasury Treasury;
    ICore Core;
    IPools Pools; 
    address keeper;
    address owner = msg.sender;

    constructor(
        address _core,
        uint256 updateInterval
    ) {
        Core = ICore(_core);
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        queueInterval = 86000; // broadcast can be made 24 hours in advance. 1.01 day after being broadcast the item will be approved for execution
    }

    function init(address _treasury, address _pool) external {
        require(msg.sender == owner, "NotAuthed");
        Treasury = ITreasury(_treasury);
        Pools = IPools(_pool);
    }

    modifier authed() {
        require(
            msg.sender == address(Core) ||
                msg.sender == address(Treasury) ||
                msg.sender == keeper ||
                msg.sender == owner,
            "NotAuthed"
        );
        _;
    }

    struct queueItem {
        address target;
        uint256 value;
        uint256 timestamp;
        bytes payload;
        opState state;
    }

    queueItem[] public queueItems;
    queueItem[] public completedItems;

    enum opState {
        Pending,
        Approved,
        Complete,
        Rejected
    }

    mapping(uint256 => queueItem) private queue; // queue of tasks to be perfromed on core contracts

    event QueueItemExecuted(bool success, bytes returnData);

    function addPaymentToken(address _token) external authed {
        Pools.addPaymentToken(_token);
    }

    function removePaymentToken(address _token) external authed {
        Pools.removePaymentToken(_token);
    }

    function handleEth(
        address from,
        address payable to
    ) external payable authed {
        if (msg.sender == address(Treasury)) {
            Treasury.releaseEth{value: msg.value}(to, msg.value);
        } else if (to == address(Treasury)) {
            Treasury.depositEth{value: msg.value}();
        } else if (from == address(Treasury) && msg.sender != address(Treasury)) {
            queueItem memory tempItem = queueItem({
                target: to,
                value: msg.value,
                timestamp: block.timestamp,
                payload: abi.encodeWithSelector(ITreasury.releaseEth.selector,to, msg.value),
                state: opState.Pending
            });
            queueItems.push(tempItem);
        } else {
            Treasury.depositEth{value: msg.value}();
        }
    }

    function handleTokens(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external payable authed {
        if (msg.sender == address(Treasury)) {
            Treasury.releaseToken(_to, _token, _amount);
        } else if(_to == address(Treasury)) {
            Treasury.depositToken(_token, _amount);
        } else if(_from == address(Treasury)) {
            queueItem memory tempItem = queueItem({
                target: _to,
                value: _amount,
                timestamp: block.timestamp,
                payload: abi.encodeWithSelector(
                    ITreasury.releaseToken.selector,
                    _to,
                    _token,
                    _amount
                ),
                state: opState.Pending
            });
            queueItems.push(tempItem);
        }
    }

    function _executeQueueItem() internal returns (bytes memory) {
        require(queueItems.length > 0, "Nothing in queue");
        queueItem memory item = queueItems[0];
        if(item.state != opState.Approved) {
            if(item.timestamp + queueInterval < block.timestamp) {
                approveQueueItem(0);
            } else {
                revert("Item is not approved");
            }
        }

        (bool ok, bytes memory mssg) = address(Treasury).call{value: item.value}(
            item.payload
        );
        require(ok, "Tx Failed");

        completedItems.push(item);
        delete queueItems[0];

        return (mssg);
    }

    function loadQueueItem(uint256 id)
        external
        view
        authed
        returns (queueItem memory)
    {
        queueItem memory _queueItem = queueItems[id];
        return (_queueItem);
    }

    function approveQueueItem(uint256 id) public authed {
        queueItem storage item = queueItems[id];
        require(
            item.state != opState.Approved || item.state != opState.Complete || item.state != opState.Rejected,
            "Item already approved"
        );
        item.state = opState.Approved;
    }

    function rejectQueueItem(uint256 id) external authed {
        queueItem storage item = queueItems[id];
        require(
            item.state != opState.Rejected || item.state != opState.Complete,
            "Item already rejected"
        );
        item.state = opState.Rejected;
    }

    function removeQueueItem(uint256 id) external authed {
        queueItem storage item = queueItems[id];
        require(item.state == opState.Rejected || item.state == opState.Complete, "Item Rejected or Completed");
        uint len = queueItems.length;
        // Move the current item to the end of the array and then pop it off.
        if (id != len - 1) {
            for (uint i = id; i < len-1; i++){
                queueItems[i] = queueItems[i+1];
            }
        }
        queueItems.pop();
    }

    function updateKeeper(address _keeper) external authed {
        keeper = _keeper;
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        queueItems.length > 0;
        uint256 time = queueItems[0].timestamp;
        upkeepNeeded = block.timestamp >= time;
        performData = bytes("");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Time interval not met");

        lastTimeStamp = block.timestamp;
        bytes memory ret = _executeQueueItem();
        emit QueueItemExecuted(true, ret);
    }

    function receiveEth() internal {
        emit Events.ReceiveEther(msg.sender, msg.value, block.timestamp);
    }

    function receiveToken(address token, uint256 amount) external authed {
        require(
            token != address(0) && amount > 0,
            "receiveToken: Can not recieve native asset"
        );
        Treasury.depositToken(token, amount);
    }

    receive() external payable {
        receiveEth();
    }

    fallback() external payable {
        receiveEth();
    }

}
