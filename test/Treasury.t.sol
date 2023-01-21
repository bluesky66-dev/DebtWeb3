// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {Treasury} from "../src/mocks/MockTreasury.sol";
import {Pools} from "../src/mocks/MockPools.sol";
import {Core} from "../src/mocks/MockCore.sol";
import {Cooperator} from "../src/mocks/MockCooperator.sol";
import {Constructor} from "../src/mocks/MockConstructor.sol";
import {Deconstructor} from "../src/mocks/MockDeconstructor.sol";

import {FreeDebtNFT} from "../src/mocks/MockFreeDebtNFT.sol";
import {DW3} from "../src/mocks/MockDW3.sol";
import {SDW3} from "../src/mocks/MockSDW3.sol";

import {SetUp} from "./utils/SetUp.sol";


contract TreasuryTest is SetUp {

    address public treasuryAddr;
    address public poolsAddr;
    address public coopAddr;

    function setUp() public {
        super.setUpTest();
        // pools.createDW3Pool()
    }

    function test_deployedAddrs() public {
        address treasury2 = address(core.treasury());
        assertTrue(address(treasury2) == address(treasury));

        address pools2 = address(core.pools());
        assertTrue(address(pools2) == address(pools));

        address coop2 = address(core.coop());
        assertTrue(address(coop2) == address(coop));
    }

    function test_deployedTokenAddr() public {
        address dw32 = address(core.dw3());
        assertTrue(address(dw32) == address(dw3));

        address sdw32 = address(core.sdw3());
        assertTrue(address(sdw32) == address(sdw3));

        address fdnft2 = address(core.fdnft());
        assertEq(address(fdnft2), address(fdnft));
    }

    function test_depositEth() public {
        vm.deal(address(this), 100 ether);
        treasury.depositEth{value: 3 ether}();
        uint ethBal = address(treasury).balance;
        uint ethBal2 = treasury.balances(address(0));
        assertEq(uint(ethBal), uint(ethBal2));
    }

    function test_depositToken() public {
        vm.startPrank(user0);
        usdt.approve(address(this), 1000000 ether);
        usdt.approve(address(treasury), 1000000 ether);
        treasury.depositToken(address(usdt), 1000 ether);

        assertEq(treasury.balances(address(usdt)), 1000 ether);
    }

    function test_depositDW3() public {
        vm.startPrank(team1);
        dw3.approve(address(treasury), 1000000 ether);
        treasury.depositDW3(1000 ether);
        assertEq(treasury.balances(address(dw3)), 1000 ether);
    }
    
    function test_depositSDW3() public {
        vm.startPrank(team1);
        sdw3.approve(address(treasury), 1000000 ether);
        treasury.depositSDW3(1000 ether);
        assertEq(treasury.balances(address(sdw3)), 1000 ether);
    }

    function test_withdrawDW3() public {
        vm.startPrank(team1);
        dw3.approve(address(treasury), 1000000 ether);
        treasury.depositDW3(1000 ether);
        vm.stopPrank();
        vm.prank(address(coop));
        treasury.withdrawDW3(500 ether);
        assertEq(treasury.balances(address(dw3)), 500 ether);
    }

    function test_withdrawSD3() public {
        vm.startPrank(team1);
        sdw3.approve(address(treasury), 1000000 ether);
        treasury.depositSDW3(1000 ether);
        vm.stopPrank();
        vm.prank(address(coop));
        treasury.withdrawSDW3(500 ether);
        assertEq(treasury.balances(address(sdw3)), 500 ether);
    }

    function test_releaseEth() public {
        vm.deal(address(this), 100 ether);
        treasury.depositEth{value: 3 ether}();
        vm.warp(1);
        vm.prank(address(coop));
        treasury.releaseEth(payable(address(coop)), 1 ether);
        uint ethBal = address(treasury).balance;
        assertEq(ethBal, 2 ether);
    }

    function test_releaseEth2() public {
        vm.deal(address(this), 100 ether);
        treasury.depositEth{value: 3 ether}();
        vm.warp(1);
        vm.prank(address(treasury));
        coop.handleEth{value: 1 ether}(payable(address(treasury)), payable(team2));
        uint ethBal = address(team2).balance;
        assertEq(ethBal, 1 ether);
    }

    function test_releaseEth3() public {
        vm.deal(address(this), 100 ether);
        treasury.depositEth{value: 3 ether}();
        vm.warp(1);
        vm.prank(address(treasury));
        coop.handleEth{value: 1 ether}(payable(address(treasury)), payable(team0));
        uint ethBal = address(team0).balance;
        assertEq(ethBal, 1 ether);
    }

    function testRevert_releaseEth() public {
        vm.deal(address(this), 100 ether);
        treasury.depositEth{value: 3 ether}();
        vm.warp(1);
        vm.startPrank(address(coop));
        vm.expectRevert();
        coop.handleEth{value: 1 ether}(payable(treasury), payable(address(coop)));
    }

    function testRevert_releaseEth2() public {
        vm.deal(address(this), 100 ether);
        treasury.depositEth{value: 3 ether}();
        vm.warp(1);
        vm.startPrank(address(treasury));
        vm.expectRevert();
        treasury.releaseEth(payable(address(coop)), 1 );
    }


    function testRevert_releaseEth3() public {
        vm.deal(address(this), 100 ether);
        treasury.depositEth{value: 3 ether}();
        vm.warp(1);
        vm.expectRevert();
        coop.handleEth{value: 1 ether}(address(treasury), payable(team0));
    }




}