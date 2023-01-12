// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title CoreComponents
/// @author Keyrxng
/// @notice The CoreComponents library contains all shared enums and structs used within the project
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
        CreditCard, // 0
        StudentLoan, // 1
        AutoLoan, // 2
        Mortgage, // 3
        PersonalLoan, // 4
        BusinessLoan, // 5
        Other // 6
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

    struct SDW3Pool {
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
        UserDebtPortfolio UserDebtPortfolio; // user debt portfolio
    }

    struct UserDebtPortfolio {
        uint256[] HeldPositions; // user debt portfolio amount
        uint256[] CollateralStaked; // user debt portfolio collateral staked
        uint256[] CollateralStakedDate; // user debt portfolio collateral staked date
    }
}