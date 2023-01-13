// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {Treasury} from "../src/Treasury.sol";
import {Pools} from "../src/Pools.sol";
import {Core} from "../src/Core.sol";
import {Cooperator} from "../src/Cooperator.sol";
import {Constructor} from "../src/Constructor.sol";
import {Deconstructor} from "../src/Deconstructor.sol";

import {FreeDebtNFT} from "../src/tokens/FreeDebtNFT.sol";
import {DW3} from "../src/tokens/DW3.sol";
import {SDW3} from "../src/tokens/SDW3.sol";

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

    /// impersonating the cooperator contract calling the treasury contract directly
    function test_releaseEth() public {
        vm.deal(address(this), 100 ether);
        treasury.depositEth{value: 3 ether}();
        vm.warp(1);
        vm.prank(address(coop));
        treasury.releaseEth(payable(address(coop)), 1 ether);
        uint ethBal = address(treasury).balance;
        assertEq(ethBal, 2 ether);
    }

    // impersonating the treasury contract calling the coop contract directly
    function test_releaseEth2() public {
        vm.deal(address(this), 100 ether);
        treasury.depositEth{value: 3 ether}();
        vm.warp(1);
        vm.prank(address(treasury));
        coop.handleEth{value: 1 ether}(payable(address(treasury)), payable(team2));
        uint ethBal = address(team2).balance;
        assertEq(ethBal, 1 ether);
    }

    // impersonating the treasury contract calling the coop contract directly
    function test_releaseEth3() public {
        vm.deal(address(this), 100 ether);
        treasury.depositEth{value: 3 ether}();
        vm.warp(1);
        vm.prank(address(treasury));
        coop.handleEth{value: 1 ether}(payable(address(treasury)), payable(team0));
        uint ethBal = address(team0).balance;
        assertEq(ethBal, 1 ether);
    }

    function test_releaseEth4() public {
        vm.deal(address(this), 100 ether);
        treasury.depositEth{value: 3 ether}();
        vm.warp(1);
        vm.prank(address(coop));
        coop.handleEth{value: 1 ether}(payable(treasury), payable(address(coop)));
        uint ethBal = address(treasury).balance;
        assertEq(ethBal, 2 ether);
    }

    function test_releaseEth5() public {
        vm.deal(address(this), 100 ether);
        treasury.depositEth{value: 3 ether}();
        vm.warp(1);
        vm.prank(address(treasury));
        treasury.releaseEth(payable(address(coop)), 1 );
        uint ethBal = address(treasury).balance;
        assertEq(ethBal, 2 ether);
    }


    // Remaning as this contract calling the coop contract directly which shouldn't transfer because it's not authed
    function testRevert_releaseEth() public {
        vm.deal(address(this), 100 ether);
        treasury.depositEth{value: 3 ether}();
        vm.warp(1);
        vm.expectRevert();
        coop.handleEth{value: 1 ether}(address(treasury), payable(team0));
    }




}