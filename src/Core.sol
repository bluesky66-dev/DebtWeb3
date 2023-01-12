// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DW3} from "./tokens/DW3.sol";
import {SDW3} from "./tokens/SDW3.sol";


library CoreComponents {
    enum DebtStatus {
        Active,
        Liquidated,
        Repaid
    }
    enum DebtPaymentStatus {
        UpToDate,
        Late,
        Defaulted
    }
    enum DebtWipeStatus {
        NotConsidered,
        Consideration,
        Declined,
        Accepted,
        Wiped
    }
    enum AgeRange {
        Under18,
        Under25,
        Under35,
        Under45,
        Under55,
        Under65,
        Over65
    }
    enum IncomeBracket {
        Under20k,
        Under30k,
        Under40k,
        Under50k,
        Under70k,
        Under85k,
        Over100k
    }
    enum DebtType {
        CreditCard,
        StudentLoan,
        AutoLoan,
        Mortgage,
        PersonalLoan,
        BusinessLoan,
        Other
    }

    struct ProtocolTVL {
        mapping(address => uint256) ProtocolTVL; // protocol total value locked
        uint256 UserTVL;
        uint256 LiquidDebtLevel;
    }

    struct DebtorInfo {
        AgeRange AgeRange;
        IncomeBracket IncomeBracket;
    }

    struct LineOfDebt {
        uint256 DebtAmount; // amount of debt total
        uint256 DebtInterest; // difference between orignal debt amount and current debt amount (debt amount * interest rate)
        uint256 DebtDuration; // date debt orginated
        uint256 DebtPurchasePrice; // price of debt at time of purchase in USD (1 USD = 1 SDW3)
        uint256 DebtPurchaseDate; // date debt was purchased
        DebtorInfo DebtorInfo; // info about the debtor
        DebtType DebtType; // type of debt
        DebtStatus DebtStatus; // status of debt
        DebtPaymentStatus DebtPaymentStatus; // status of debt payment
        DebtWipeStatus DebtWipeStatus; // status of debt wipe
    }

    struct DW3Pool {
        uint256 PoolAmount; // amount of debt in the liquid debt pool
        uint256 RewardsPerShare; // rewards per share of the pool
        uint256 LastRewardBlock; // last block rewards were distributed
        uint256 TotalRewards; // total rewards to be distributed
        uint256 totalShares; // total shares of the pool available at creation
        uint256 rewardsPerSecond; // rewards per second of the pool
        address[] stakers; // array of stakers
    }

    struct SWD3Pool {
        uint256 PoolAmount; // amount of SDW3 in the SDW3 pool
        uint256 RewardsPerShare; // rewards per share of the SDW3 pool
        uint256 LastRewardBlock; // last block rewards were distributed
        uint256 TotalRewards; // total rewards distributed
        uint256 totalShares; // total shares of the pool available set at creation
        uint256 rewardsPerSecond; // rewards per second of the pool
        address[] stakers; // array of stakers
    }

    struct User {
        mapping(uint256 => uint256) dw3PoolStakes; // user pool stakes
        mapping(uint256 => uint256) sdw3PoolStakes; // user pool stakes
        uint256 UserDW3PoolAmount; // user liquid debt pool amount
        uint256 UserDW3PoolRewardsPerSharePaid; // user liquid debt pool rewards per share paid
        uint256 UserDW3PoolLastRewardBlock; // user liquid debt pool last reward block
        uint256 UserSWD3PoolAmount; // user SDW3 pool amount
        uint256 UserSWD3PoolRewardsPerSharePaid; // user SDW3 pool rewards per share paid
        uint256 UserSWD3PoolLastRewardBlock; // user SDW3 pool last reward block
        UserDebtPortfolio UserDebtPortfolio; // user debt portfolio
    }

    struct UserDebtPortfolio {
        uint256[] HeldPositions; // user debt portfolio amount
        uint256[] CollateralStaked; // user debt portfolio collateral staked
        uint256[] CollateralStakedDate; // user debt portfolio collateral staked date
    }
}

/// @title Core
/// @author Keyrxng
/// @notice The Core contract is the inner mechanics of the protocol which isn't interacted with directly
contract Core is ReentrancyGuard, Ownable {
    using CoreComponents for CoreComponents.ProtocolTVL;
    using CoreComponents for CoreComponents.DW3Pool;
    using CoreComponents for CoreComponents.SWD3Pool;
    using SafeERC20 for DW3;
    using SafeERC20 for SDW3;
    using SafeERC20 for IERC20;

    mapping(address => CoreComponents.User) public Users;
    mapping(uint256 => CoreComponents.DW3Pool) public DW3Poolages;
    mapping(uint256 => CoreComponents.SWD3Pool) public SDW3Poolages;

    mapping(address => mapping(uint256 => uint256)) UserDW3RewardsPerSharePaid; // user rewards per share paid || [msg.sender][_poolId] = _rewardsPerSharePaid
    mapping(address => mapping(uint256 => uint256)) UserDW3RewardsPerShareUnpaid; // user rewards per share unpaid || [msg.sender][_poolId] = _rewardsPerShareUnpaid
    mapping(address => mapping(uint256 => uint256)) UserSDW3RewardsPerSharePaid; // user rewards per share paid || [msg.sender][_poolId] = _rewardsPerShareUnpaid
    mapping(address => mapping(uint256 => uint256)) UserSDW3RewardsPerShareUnpaid; // user rewards per share unpaid || [msg.sender][_poolId] = _rewardsPerShareUnpaid

    mapping(address => bool) public paymentTokens;

    bool public paused;

    uint256 public rewardInterval = 86000;

    address treasury;

    DW3 dw3;
    SDW3 sdw3;

    CoreComponents.ProtocolTVL ProtocolTVL;
    CoreComponents.DW3Pool[] DW3Pools;
    CoreComponents.SWD3Pool[] SDW3Pools;

    event StakeInDW3(address indexed user, uint256 indexed amount);
    event StakeInSWD3(address indexed user, uint256 indexed amount);

    event WithdrawFromDW3(address indexed user, uint256 amount);
    event WithdrawFromSWD3(address indexed user, uint256 amount);

    event ClaimDW3(address who, uint256 amount);
    event ClaimSDW3(address who, uint256 amount);

    event DW3PoolCreated(uint256 poolId, uint256 rps, uint256 totalRewards);
    event SDW3PoolCreated(uint256 poolId, uint256 rps, uint256 totalRewards);

    error Paused();
    error TokenNotSupported();
    error InsufficientBalance(uint256 requested, uint256 available);
    error PoolNotActiveYet(uint256 poolId, uint256 whenActive);
    error InsufficientRewardBalance(uint256 requested, uint256 available);

    constructor() {
        paused = false;
        dw3 = new DW3();
        sdw3 = new SDW3();

        createDW3Pool(0, 4, 250_000_000); // 1st Pool, 0 deposited, 4 rewards per second, 250M DW3 in reward pool
        createSDW3Pool(0, 15, 250_000_000); // 1st Pool, 0 deposited, 15 rewards per second, 250M SDW3 in reward pool
        treasury = msg.sender;
    }

    modifier notPaused() {
        if (paused) revert Paused();
        _;
    }

    function addPaymentToken(address _token) public onlyOwner {
        paymentTokens[_token] = true;
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
    ) public onlyOwner {
        address[] memory staker = new address[](0);
        staker[0] = treasury;
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
        DW3Poolages[DW3Pools.length - 1] = pool;

        emit DW3PoolCreated(DW3Pools.length - 1, _rps, _totalRewards);
    }

    function createSDW3Pool(
        uint256 _totalShares,
        uint256 _totalRewards,
        uint256 _rps
    ) public onlyOwner {
        address[] memory staker = new address[](0);
        staker[0] = treasury;
        CoreComponents.SWD3Pool memory pool = CoreComponents.SWD3Pool(
            0,
            0,
            block.timestamp,
            _totalRewards,
            _totalShares,
            _rps,
            staker
        );
        SDW3Pools.push(pool);
        SDW3Poolages[SDW3Pools.length - 1] = pool;

        emit SDW3PoolCreated(SDW3Pools.length - 1, _rps, _totalRewards);
    }

    function stakeInDW3(
        uint256 _amount,
        address token,
        uint8 _poolId
    ) public notPaused {
        if (DW3Pools[_poolId].LastRewardBlock > block.timestamp) {
            revert PoolNotActiveYet(_poolId, DW3Pools[_poolId].LastRewardBlock);
        }

        if (!paymentTokens[token]) {
            revert TokenNotSupported();
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
        emit StakeInDW3(msg.sender, _amount);
    }

    function stakeInSWD3(uint256 _amount, uint8 _poolId) public notPaused {
        if (SDW3Pools[_poolId].LastRewardBlock > block.timestamp) {
            revert PoolNotActiveYet(
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
        emit StakeInSWD3(msg.sender, _amount);
    }

    function _updatePools(bool _isDw3, uint256 _poolId) internal {
        if (_isDw3) {
            for (uint256 i = 0; i < DW3Pools[_poolId].stakers.length; i++) {
                CoreComponents.DW3Pool storage pool = DW3Pools[_poolId];
                address user = pool.stakers[i];
                uint256 pending = (UserDW3RewardsPerShareUnpaid[user][_poolId] *
                pool.totalShares) / pool.PoolAmount;
                pool.RewardsPerShare = (pool.TotalRewards / pool.totalShares);
                uint256 reward = UserDW3RewardsPerShareUnpaid[user][_poolId] * pool.RewardsPerShare;
                uint256 actualPending = pending / reward;
                UserDW3RewardsPerSharePaid[user][_poolId] += actualPending;
                pool.LastRewardBlock = block.timestamp;
            }
        } else {
            for (uint256 i = 0; i < SDW3Pools[_poolId].stakers.length; i++) {
                CoreComponents.SWD3Pool storage pool = SDW3Pools[_poolId];
                address user = pool.stakers[i];
                uint256 pending = (UserSDW3RewardsPerShareUnpaid[user][_poolId] *
                pool.totalShares) / pool.PoolAmount;
                pool.RewardsPerShare = (pool.TotalRewards / pool.totalShares);
                uint256 reward = UserSDW3RewardsPerShareUnpaid[user][_poolId] * pool.RewardsPerShare;
                uint256 actualPending = pending / reward;
                UserSDW3RewardsPerSharePaid[user][_poolId] += actualPending;
                pool.LastRewardBlock = block.timestamp;
            }
        }
    }

    function claimDW3(uint8 _poolId) public nonReentrant notPaused {
        _updatePools(true, _poolId);
        uint256 unpaidPending = UserDW3RewardsPerSharePaid[msg.sender][_poolId] ;

        if (
            Users[msg.sender].dw3PoolStakes[_poolId] == 0 || unpaidPending == 0
        ) {
            revert InsufficientBalance({
                requested: unpaidPending,
                available: Users[msg.sender].dw3PoolStakes[_poolId]
            });
        }
        dw3.mint(msg.sender, unpaidPending);
        emit ClaimDW3(msg.sender, unpaidPending);
    }

    function claimSDW3(uint8 _poolId) public nonReentrant notPaused {
        _updatePools(false, _poolId);
        uint256 unpaidPending = UserSDW3RewardsPerSharePaid[msg.sender][_poolId] ;

        if (
            Users[msg.sender].dw3PoolStakes[_poolId] == 0 || unpaidPending == 0
        ) {
            revert InsufficientBalance({
                requested: unpaidPending,
                available: Users[msg.sender].dw3PoolStakes[_poolId]
            });
        }

        sdw3.mint(msg.sender, unpaidPending);
        emit ClaimSDW3(msg.sender, unpaidPending);
    }

    function withdrawFromDW3(
        uint256 _amount,
        uint8 _poolId,
        address _token
    ) public nonReentrant notPaused {
        if (Users[msg.sender].dw3PoolStakes[_poolId] < _amount) {
            revert InsufficientBalance({
                requested: _amount,
                available: Users[msg.sender].dw3PoolStakes[_poolId]
            });
        }
        _updatePools(true, _poolId);

        uint256 minusShares = calcShares(_amount, _poolId, true);

        DW3Poolages[_poolId].totalShares -= minusShares;
        DW3Poolages[_poolId].PoolAmount -= _amount;

        DW3Pools[_poolId].totalShares -= minusShares;
        DW3Pools[_poolId].PoolAmount -= _amount;

        Users[msg.sender].dw3PoolStakes[_poolId] -= _amount;

        ProtocolTVL.ProtocolTVL[_token] -= _amount;

        IERC20(_token).transfer(msg.sender, _amount);
        claimDW3(_poolId);
        emit WithdrawFromDW3(msg.sender, _amount);
    }

    function withdrawFromSWD3(uint256 _amount, uint8 _poolId)
        public
        nonReentrant
        notPaused
    {
        if (Users[msg.sender].sdw3PoolStakes[_poolId] < _amount) {
            revert InsufficientBalance({
                requested: _amount,
                available: Users[msg.sender].sdw3PoolStakes[_poolId]
            });
        }
        _updatePools(false, _poolId);
        uint256 minusShares = calcShares(_amount, _poolId, true);
        SDW3Poolages[_poolId].totalShares -= minusShares;
        SDW3Poolages[_poolId].PoolAmount -= _amount;

        SDW3Pools[_poolId].totalShares -= minusShares;
        SDW3Pools[_poolId].PoolAmount -= _amount;
        Users[msg.sender].sdw3PoolStakes[_poolId] -= _amount;
        sdw3.transfer(msg.sender, _amount);
        claimSDW3(_poolId);
        emit WithdrawFromSWD3(msg.sender, _amount);
    }

    function pauseProtocol() public onlyOwner {
        paused = true;
    }

    function unpauseProtocol() public onlyOwner {
        paused = false;
    }

    function receiveEther() public payable nonReentrant {
        uint256 _amount = msg.value;

        /// @todo pull usd of msg.value 



        dw3.mint(address(this), _amount);
        ProtocolTVL.ProtocolTVL[address(dw3)] += _amount;
        emit ReceiveEther(msg.sender, _amount, block.timestamp);
    }

    event ReceiveEther(address indexed sender, uint256 amount, uint256 timestamp);
    receive() external payable {
        receiveEther();
    }
}
