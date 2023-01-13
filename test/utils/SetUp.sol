// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {Treasury} from "../../src/mocks/MockTreasury.sol";
import {Pools} from "../../src/mocks/MockPools.sol";
import {Core} from "../../src/mocks/MockCore.sol";
import {Cooperator} from "../../src/mocks/MockCooperator.sol";
import {Constructor} from "../../src/mocks/MockConstructor.sol";
import {Deconstructor} from "../../src/mocks/MockDeconstructor.sol";

import {FreeDebtNFT} from "../../src/mocks/MockFreeDebtNFT.sol";
import {DW3} from "../../src/mocks/MockDW3.sol";
import {SDW3} from "../../src/mocks/MockSDW3.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";


contract SetUp is Test {

    Treasury treasury;
    Pools pools;
    Cooperator coop;
    Core core;
    Constructor cons;
    Deconstructor des;

    DW3 dw3;
    SDW3 sdw3;
    FreeDebtNFT fdnft;

    MockERC20 usdt;
    MockERC20 usdc;
    MockERC20 busd;
    MockERC20 weth;

    address public user0;
    address public user1;
    address public user2;

    address public team0;
    address public team1;
    address public team2;

    function setUpTest() public {
        dw3 = new DW3();
        sdw3 = new SDW3();
        fdnft = new FreeDebtNFT();

        usdt = new MockERC20("USDT", "USDT", 300_000_000);
        usdc = new MockERC20("USDC", "USDC", 300_000_000);
        busd = new MockERC20("BUSD", "BUSD", 300_000_000);
        weth = new MockERC20("WETH", "ETH", 100_000_000);

        core = new Core(address(dw3), address(sdw3), address(fdnft));

        treasury = core.treasury();
        pools = core.pools();
        coop = core.coop();
        cons = core.cons();

        user0 = vm.addr(0x1000);
        user1 = vm.addr(0x2000);
        user2 = vm.addr(0x3000);

        team0 = vm.addr(0x4000);
        team1 = vm.addr(0x5000);
        team2 = vm.addr(0x6000);

        dw3.mint(team0, 250_000_000 ether);
        dw3.mint(team1, 100_000 ether);
        dw3.mint(team2, 100_000 ether);

        sdw3.mint(team0, 250_000_000 ether);
        sdw3.mint(team1, 10_000 ether);
        sdw3.mint(team2, 10_000 ether);

        usdt.transfer(user0, 1000 ether);
        usdt.transfer(user1, 1000 ether);
        usdt.transfer(user2, 1000 ether);

        usdc.transfer(user0, 1000 ether);
        usdc.transfer(user1, 1000 ether);
        usdc.transfer(user2, 1000 ether);

        busd.transfer(user0, 1000 ether);
        busd.transfer(user1, 1000 ether);
        busd.transfer(user2, 1000 ether);
        
        weth.transfer(user0, 1000 ether);
        weth.transfer(user1, 1000 ether);
        weth.transfer(user2, 1000 ether);

        // usdt.approve(address(pools), type(uint).max);
        // usdc.approve(address(pools), type(uint).max);
        // busd.approve(address(pools), type(uint).max);

        // weth.approve(address(pools), type(uint).max);
        // weth.approve(address(core), type(uint).max);
        // weth.approve(address(coop), type(uint).max);
        // weth.approve(address(treasury), type(uint).max);

        // usdt.approve(address(coop), type(uint).max);
        // usdc.approve(address(coop), type(uint).max);
        // busd.approve(address(coop), type(uint).max);
        // weth.approve(address(coop), type(uint).max);
        
        // sdw3.approve(address(coop), type(uint).max);
        // sdw3.approve(address(treasury), type(uint).max);
        // sdw3.approve(address(core), type(uint).max);

        // dw3.approve(address(treasury), type(uint).max);
        // dw3.approve(address(core), type(uint).max);
        // dw3.approve(address(coop), type(uint).max);



    }

}