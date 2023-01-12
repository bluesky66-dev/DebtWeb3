// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DW3} from "./tokens/DW3.sol";
import {SDW3} from "./tokens/SDW3.sol";

import {CoreComponents} from "./lib/CoreComponents.sol";
import {Events} from "./lib/Events.sol";
import {Errors} from "./lib/Errors.sol";

/// @title Pools
/// @author Keyrxng
/// @notice The Pools contract is the inner mechanics of the protocol which isn't interacted with directly
contract Pools is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;
    using CoreComponents for CoreComponents.DW3Pool;
    using CoreComponents for CoreComponents.SDW3Pool;

    bool private paused;
    uint256 private rewardInterval = 86000;

    CoreComponents.DW3Pool[] DW3Pools;
    CoreComponents.SDW3Pool[] SDW3Pools;
    CoreComponents.ProtocolTVL ProtocolTVL;

    DW3 private dw3;
    SDW3 private sdw3;


    address  private Treasury;
    address  private Coop;
    
    bytes32 public constant CORE_ROLE = keccak256("CORE_ROLE");
    bytes32 public constant COOP_ROLE = keccak256("COOP_ROLE");
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    mapping(address => bool) private paymentTokens;
    mapping(address => CoreComponents.User) private Users;
    mapping(address => mapping(uint256 => uint256))
        private UserDW3RewardsPerSharePaid; // user rewards per share paid || [msg.sender][_poolId] = _rewardsPerSharePaid
    mapping(address => mapping(uint256 => uint256))
        private UserDW3RewardsPerShareUnpaid; // user rewards per share unpaid || [msg.sender][_poolId] = _rewardsPerShareUnpaid
    mapping(address => mapping(uint256 => uint256))
        private UserSDW3RewardsPerSharePaid; // user rewards per share paid || [msg.sender][_poolId] = _rewardsPerShareUnpaid
    mapping(address => mapping(uint256 => uint256))
        private UserSDW3RewardsPerShareUnpaid; // user rewards per share unpaid || [msg.sender][_poolId] = _rewardsPerShareUnpaid

    modifier notPaused() {
        if (paused) revert Errors.Paused();
        _;
    }

    constructor(DW3 _dw3, SDW3 _sdw3, address _treasury, address _coop) {
        dw3 = _dw3;
        sdw3 = _sdw3;
        Coop = _coop;


        createDW3Pool(10000, 250_000_000, 1); // 1st Pool, 10k shares, 250M DW3 in reward pool, 1 reward per second
        createSDW3Pool(10000, 250_000_000, 1); // 1st Pool, 10k shares, 250M SDW3 in reward pool, 1 reward per second

        Treasury = _treasury;
        _setupRole(CORE_ROLE, msg.sender);
        _setupRole(COOP_ROLE, Coop);
        _setupRole(TREASURY_ROLE, Treasury);
    }

    function addPaymentToken(address _token) public onlyRole(COOP_ROLE) {
        paymentTokens[_token] = true;
    }

    function removePaymentToken(address _token) external onlyRole(COOP_ROLE) {
        paymentTokens[_token] = false;
    }

    function calcShares(
        uint256 _amount,
        uint256 _poolId,
        bool _isDW3
    ) public view returns (uint256) {
        if (_isDW3) {
            return
                ((_amount * 1e18) * DW3Pools[_poolId].totalShares) /
                DW3Pools[_poolId].PoolAmount;
        } else {
            return
                ((_amount * 1e18) * SDW3Pools[_poolId].totalShares) /
                SDW3Pools[_poolId].PoolAmount;
        }
    }

    function createDW3Pool(
        uint256 _totalShares,
        uint256 _totalRewards,
        uint256 _rps
    ) public onlyRole(COOP_ROLE) {
        address[] memory staker = new address[](0);
        staker[0] = Treasury;
        CoreComponents.DW3Pool memory pool = CoreComponents.DW3Pool(
            0,
            0,
            block.timestamp,
            _totalRewards,
            _totalShares,
            _rps,
            staker
        );
        DW3Pools.push(pool);

        emit Events.DW3PoolCreated(DW3Pools.length - 1, _rps, _totalRewards);
    }

    function createSDW3Pool(
        uint256 _totalShares,
        uint256 _totalRewards,
        uint256 _rps
    ) public onlyRole(COOP_ROLE) {
        address[] memory staker = new address[](0);
        staker[0] = Treasury;
        CoreComponents.SDW3Pool memory pool = CoreComponents.SDW3Pool(
            0,
            0,
            block.timestamp,
            _totalRewards,
            _totalShares,
            _rps,
            staker
        );
        SDW3Pools.push(pool);

        emit Events.SDW3PoolCreated(SDW3Pools.length - 1, _rps, _totalRewards);
    }

    function stakeEthInDW3(
        uint256 _amount
    ) external payable notPaused {
        if (DW3Pools[0].LastRewardBlock > block.timestamp) {
            revert Errors.PoolNotActiveYet(
                0,
                DW3Pools[0].LastRewardBlock
            );
        }

        _updatePools(true, 0);
        require(msg.value == _amount, "You must stake more than 0 eth.");

        uint256 ts = calcShares(_amount, 0, true);
        UserDW3RewardsPerShareUnpaid[msg.sender][0] += ts;

        DW3Pools[0].PoolAmount += _amount;
        DW3Pools[0].stakers.push(msg.sender);

        Users[msg.sender].dw3PoolStakes[0] += _amount;

        ProtocolTVL.ProtocolTVL[address(0)] += _amount;

        emit Events.StakeInDW3(msg.sender, _amount);
    }

    function stakeInDW3(
        uint256 _amount,
        address token,
        uint8 _poolId
    ) public notPaused {
        if (DW3Pools[_poolId].LastRewardBlock > block.timestamp) {
            revert Errors.PoolNotActiveYet(
                _poolId,
                DW3Pools[_poolId].LastRewardBlock
            );
        }

        if (!paymentTokens[token]) {
            revert Errors.TokenNotSupported();
        }

        _updatePools(true, _poolId);
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 ts = calcShares(_amount, _poolId, true);
        UserDW3RewardsPerShareUnpaid[msg.sender][_poolId] += ts;

        DW3Pools[_poolId].PoolAmount += _amount;
        DW3Pools[_poolId].totalShares += ts;
        DW3Pools[_poolId].stakers.push(msg.sender);

        Users[msg.sender].dw3PoolStakes[_poolId] += _amount;
        ProtocolTVL.ProtocolTVL[token] += _amount;
        emit Events.StakeInDW3(msg.sender, _amount);
    }

    function stakeInSWD3(uint256 _amount, uint8 _poolId) public notPaused {
        if (SDW3Pools[_poolId].LastRewardBlock > block.timestamp) {
            revert Errors.PoolNotActiveYet(
                _poolId,
                SDW3Pools[_poolId].LastRewardBlock
            );
        }
        _updatePools(false, _poolId);
        dw3.transferFrom(msg.sender, address(this), _amount);
        uint256 ts = calcShares(_amount, _poolId, false);

        UserSDW3RewardsPerShareUnpaid[msg.sender][_poolId] += ts;

        SDW3Pools[_poolId].totalShares += ts;
        SDW3Pools[_poolId].PoolAmount += _amount;
        SDW3Pools[_poolId].stakers.push(msg.sender);

        Users[msg.sender].sdw3PoolStakes[_poolId] += _amount;
        ProtocolTVL.ProtocolTVL[address(dw3)] += _amount;
        emit Events.StakeInSWD3(msg.sender, _amount);
    }

    function _updatePools(bool _isDw3, uint256 _poolId) internal {
        if (_isDw3) {
            for (uint256 i = 0; i < DW3Pools[_poolId].stakers.length; i++) {
                CoreComponents.DW3Pool storage pool = DW3Pools[_poolId];
                address user = pool.stakers[i];
                uint256 pending = (UserDW3RewardsPerShareUnpaid[user][_poolId] *
                    pool.totalShares) / pool.PoolAmount;
                pool.RewardsPerShare = (pool.TotalRewards / pool.totalShares);
                uint256 reward = UserDW3RewardsPerShareUnpaid[user][_poolId] *
                    pool.RewardsPerShare;
                uint256 actualPending = pending / reward;
                UserDW3RewardsPerSharePaid[user][_poolId] += actualPending;
                pool.LastRewardBlock = block.timestamp;
            }
        } else {
            for (uint256 i = 0; i < SDW3Pools[_poolId].stakers.length; i++) {
                CoreComponents.SDW3Pool storage pool = SDW3Pools[_poolId];
                address user = pool.stakers[i];
                uint256 pending = (UserSDW3RewardsPerShareUnpaid[user][
                    _poolId
                ] * pool.totalShares) / pool.PoolAmount;
                pool.RewardsPerShare = (pool.TotalRewards / pool.totalShares);
                uint256 reward = UserSDW3RewardsPerShareUnpaid[user][_poolId] *
                    pool.RewardsPerShare;
                uint256 actualPending = pending / reward;
                UserSDW3RewardsPerSharePaid[user][_poolId] += actualPending;
                pool.LastRewardBlock = block.timestamp;
            }
        }
    }

    function claimDW3(uint8 _poolId) public nonReentrant notPaused {
        _updatePools(true, _poolId);
        uint256 unpaidPending = UserDW3RewardsPerSharePaid[msg.sender][_poolId];

        if (
            Users[msg.sender].dw3PoolStakes[_poolId] == 0 || unpaidPending == 0
        ) {
            revert Errors.InsufficientBalance({
                requested: unpaidPending,
                available: Users[msg.sender].dw3PoolStakes[_poolId]
            });
        }
        dw3.mint(msg.sender, unpaidPending);
        emit Events.ClaimDW3(msg.sender, unpaidPending);
    }

    function claimSDW3(uint8 _poolId) public nonReentrant notPaused {
        _updatePools(false, _poolId);
        uint256 unpaidPending = UserSDW3RewardsPerSharePaid[msg.sender][
            _poolId
        ];

        if (
            Users[msg.sender].dw3PoolStakes[_poolId] == 0 || unpaidPending == 0
        ) {
            revert Errors.InsufficientBalance({
                requested: unpaidPending,
                available: Users[msg.sender].dw3PoolStakes[_poolId]
            });
        }

        sdw3.mint(msg.sender, unpaidPending);
        emit Events.ClaimSDW3(msg.sender, unpaidPending);
    }

    function withdrawFromDW3(
        uint256 _amount,
        uint8 _poolId,
        address _token
    ) public nonReentrant notPaused {
        if (Users[msg.sender].dw3PoolStakes[_poolId] < _amount) {
            revert Errors.InsufficientBalance({
                requested: _amount,
                available: Users[msg.sender].dw3PoolStakes[_poolId]
            });
        }
        _updatePools(true, _poolId);

        uint256 minusShares = calcShares(_amount, _poolId, true);

        DW3Pools[_poolId].totalShares -= minusShares;
        DW3Pools[_poolId].PoolAmount -= _amount;

        Users[msg.sender].dw3PoolStakes[_poolId] -= _amount;

        ProtocolTVL.ProtocolTVL[_token] -= _amount;

        IERC20(_token).transfer(msg.sender, _amount);
        claimDW3(_poolId);
        emit Events.WithdrawFromDW3(msg.sender, _amount);
    }

    function withdrawFromSWD3(uint256 _amount, uint8 _poolId)
        public
        nonReentrant
        notPaused
    {
        if (Users[msg.sender].sdw3PoolStakes[_poolId] < _amount) {
            revert Errors.InsufficientBalance({
                requested: _amount,
                available: Users[msg.sender].sdw3PoolStakes[_poolId]
            });
        }
        _updatePools(false, _poolId);
        uint256 minusShares = calcShares(_amount, _poolId, true);

        SDW3Pools[_poolId].totalShares -= minusShares;
        SDW3Pools[_poolId].PoolAmount -= _amount;
        Users[msg.sender].sdw3PoolStakes[_poolId] -= _amount;
        dw3.transfer(msg.sender, _amount);
        claimSDW3(_poolId);
        emit Events.WithdrawFromSWD3(msg.sender, _amount);
    }

    function pauseProtocol() public onlyRole(CORE_ROLE) returns(bool) {
        paused = !paused;
        if(paused) {
        emit Events.Paused();
        } else {
            emit Events.Unpaused();
        }
        return paused;
    }

}
