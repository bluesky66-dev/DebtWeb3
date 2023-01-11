// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DW3} from "./tokens/DW3.sol";
import {SDW3} from "./tokens/SDW3.sol";
import {Deconstructor} from "./Deconstructor.sol";

library CoreComponents {

    enum DebtStatus { Active, Liquidated, Repaid }
    enum DebtPaymentStatus { UpToDate, Late, Defaulted}
    enum DebtWipeStatus {NotConsidered, Consideration, Declined, Accepted, Wiped}
    enum AgeRange { Under18, Under25, Under35, Under45, Under55, Under65, Over65 }
    enum IncomeBracket { Under20k, Under30k, Under40k, Under50k, Under70k, Under85k, Over100k}
    enum DebtType { CreditCard, StudentLoan, AutoLoan, Mortgage, PersonalLoan, BusinessLoan, Other }

    struct ProtocolTVL {
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
        uint256 RewardsPerShare; // rewards per share of the liquid debt pool
        uint256 LastRewardBlock; // last block rewards were distributed
        uint256 TotalRewards; // total rewards distributed
    }

    struct SWD3Pool {
        uint256 PoolAmount; // amount of SDW3 in the SDW3 pool
        uint256 RewardsPerShare; // rewards per share of the SDW3 pool
        uint256 LastRewardBlock; // last block rewards were distributed
        uint256 TotalRewards; // total rewards distributed
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
contract Core is Ownable {

    using CoreComponents for CoreComponents.ProtocolTVL;
    using CoreComponents for CoreComponents.DW3Pool;
    using CoreComponents for CoreComponents.SWD3Pool;
    using SafeERC20 for DW3;
    using SafeERC20 for SDW3;
    using SafeERC20 for IERC20;

    mapping(address => CoreComponents.User) public Users;
    mapping(uint256 => CoreComponents.DW3Pool) public DW3Poolages;
    mapping(uint256 => CoreComponents.SWD3Pool) public SDW3Poolages;
    
    bool paused;

    DW3 dw3;
    SDW3 sdw3;

    CoreComponents.ProtocolTVL ProtocolTVL;
    CoreComponents.DW3Pool[] DW3Pools;
    CoreComponents.SWD3Pool[] SDW3Pools;

    event StakeInDW3(address indexed user, uint256 indexed amount);
    event StakeInSWD3(address indexed user, uint256 indexed amount);

    event WithdrawFromDW3(address indexed user, uint256 amount);
    event WithdrawFromSWD3(address indexed user, uint256 amount);

    event DW3PoolCreated(uint poolId, uint256 poolAmnt, uint256 rps, uint256 lastRewardBlock, uint256 totalRewards);
    event SDW3PoolCreated(uint poolId, uint256 poolAmnt, uint256 rps, uint256 lastRewardBlock, uint256 totalRewards);
    
    constructor()
    
     {
        paused = false;
        dw3 = new DW3();
        sdw3 = new SDW3();
    }
    

    function getProtocolTVL() public view returns (uint256, uint256) {
        return (ProtocolTVL.UserTVL, ProtocolTVL.LiquidDebtLevel);
    }

    function stakeInDW3(uint256 _amount, address token, uint8 _poolId) public {
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        DW3Poolages[_poolId].PoolAmount += _amount;
        DW3Pools[_poolId].PoolAmount += _amount;
        Users[msg.sender].dw3PoolStakes[_poolId] += _amount;
        ProtocolTVL.UserTVL += _amount;
        emit StakeInDW3(msg.sender, _amount);
    }
    
    function stakeInSWD3(uint256 _amount, uint8 _poolId) public {
        dw3.transferFrom(msg.sender, address(this), _amount);
        SDW3Poolages[_poolId].PoolAmount += _amount;
        SDW3Pools[_poolId].PoolAmount += _amount;
        Users[msg.sender].dw3PoolStakes[_poolId] += _amount;
        emit StakeInSWD3(msg.sender, _amount);
    }

    error InsufficientBalance(uint256 requested, uint256 available);
    function withdrawFromDW3(uint256 _amount, uint8 _poolId) public {
        if(Users[msg.sender].dw3PoolStakes[_poolId] < _amount) {
            revert InsufficientBalance({
                requested: _amount,
                available: Users[msg.sender].dw3PoolStakes[_poolId]
            });
        }
        
        DW3Poolages[_poolId].PoolAmount -= _amount;
        DW3Pools[_poolId].PoolAmount -= _amount;
        Users[msg.sender].dw3PoolStakes[_poolId] -= _amount;        

        ProtocolTVL.UserTVL -= _amount;

        dw3.transfer(msg.sender, _amount);
        emit WithdrawFromDW3(msg.sender, _amount);
    }

    function withdrawFromSWD3(uint256 _amount, uint8 _poolId) public {
        if(Users[msg.sender].sdw3PoolStakes[_poolId] < _amount) {
            revert InsufficientBalance({
                requested: _amount,
                available: Users[msg.sender].sdw3PoolStakes[_poolId]
            });
        }
        SDW3Poolages[_poolId].PoolAmount -= _amount;
        SDW3Pools[_poolId].PoolAmount -= _amount;
        Users[msg.sender].sdw3PoolStakes[_poolId] -= _amount;
        sdw3.transfer(msg.sender, _amount);
        emit WithdrawFromSWD3(msg.sender, _amount);
    }

    function pauseProtocol() public onlyOwner {
        paused = true;
    }

    function unpauseProtocol() public onlyOwner {
        paused = false;
    }

    function createDW3Pool(uint256 _poolAmnt, uint256 _rps, uint256 _totalRewards) public {
        CoreComponents.DW3Pool memory pool = 
        CoreComponents.DW3Pool(_poolAmnt, _rps, block.number, _totalRewards);
        DW3Pools.push(pool);
        DW3Poolages[DW3Pools.length -1] = pool;

        emit DW3PoolCreated(DW3Pools.length -1, _poolAmnt, _rps, block.number, _totalRewards);
    }

    function createSWD3Pool(uint256 _poolAmnt, uint256 _rps, uint256 _totalRewards) public {
        CoreComponents.SWD3Pool memory pool = 
        CoreComponents.SWD3Pool(_poolAmnt, _rps, block.number, _totalRewards);
        SDW3Pools.push(pool);
        SDW3Poolages[SDW3Pools.length -1] = pool;

        emit SDW3PoolCreated(SDW3Pools.length -1, _poolAmnt, _rps, block.number, _totalRewards);
    }

}