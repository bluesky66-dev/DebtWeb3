// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Treasury
/// @author Keyrxng
/// @notice The Treasury contract manages the DebtWeb3 protocol treasury
contract Treasury is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    IERC20 public DW3;
    IERC20 public SDW3;

    address Core;
    address Coop;

        
    mapping(address => uint256) public balances;
    
    event ReleasedEth(address indexed to, uint256 indexed amount);
    event ReleasedToken(address indexed to, address indexed token, uint256 indexed amount);    
    event ReceivedEth(address indexed from, uint256 indexed amount);
    event ReceivedToken(address indexed from, address indexed token, uint256 indexed amount);

    constructor(IERC20 _DW3, IERC20 _SDW3, address _core, address _coop) {
        DW3 = _DW3;
        SDW3 = _SDW3;
        Core = _core;
        Coop = _coop;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TREASURY_ROLE, Coop);
    }

    function depositEth() external payable {
        _receiveEth(tx.origin, msg.value);
    }

    function depositToken(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _receiveToken(tx.origin, token, amount);
    }

    function depositDW3(uint256 amount) external onlyRole(TREASURY_ROLE){
        DW3.safeTransferFrom(msg.sender, address(this), amount);
        _receiveToken(msg.sender, address(DW3), amount);
    }

    function depositSDW3(uint256 amount) external onlyRole(TREASURY_ROLE){
        SDW3.safeTransferFrom(msg.sender, address(this), amount);
        _receiveToken(msg.sender, address(SDW3), amount);
    }

    function withdrawDW3(uint256 amount) external onlyRole(TREASURY_ROLE) {
        DW3.safeTransfer(msg.sender, amount);
        _releaseToken(msg.sender, address(DW3), amount);
    }

    function withdrawSDW3(uint256 amount) external onlyRole(TREASURY_ROLE){
        SDW3.safeTransfer(msg.sender, amount);
        _releaseToken(msg.sender, address(SDW3), amount);
    }

    function releaseEth(address payable to, uint256 amount) external payable onlyRole(TREASURY_ROLE) {
        _releaseEth(to, amount);
    }

    function releaseToken(address to, address token, uint256 amount) external onlyRole(TREASURY_ROLE) {
        _releaseToken(to, token, amount);
    }

    function getDW3Balance() public view returns (uint256) {
        return DW3.balanceOf(address(this));
    }

    function getSDW3Balance() public view returns (uint256) {
        return SDW3.balanceOf(address(this));
    }

    function getDW3Allowance() public view returns (uint256) {
        return DW3.allowance(msg.sender, address(this));
    }

    function getSDW3Allowance() public view returns (uint256) {
        return SDW3.allowance(msg.sender, address(this));
    }

    function getDW3TotalSupply() public view returns (uint256) {
        return DW3.totalSupply();
    }

    function getSDW3TotalSupply() public view returns (uint256) {
        return SDW3.totalSupply();
    }


    function _releaseToken(address _to, address _token, uint256 _amount) internal {
        require(_amount > 0, "Treasury: Cannot release 0 tokens");
        balances[_token] -= _amount;
        IERC20(_token).safeTransfer(_to, _amount);
        emit ReleasedToken(_to, _token, _amount);
    }

    function _releaseEth(address payable _to, uint256 _amount) internal {
        require(_amount > 0, "Treasury: Cannot release 0 ETH");
        require(_to != address(0), "Treasury: Cannot release ETH to the zero address");
        require(balances[address(0) /* ETH */] >= _amount, "Treasury: Not enough ETH in the treasury");
        balances[address(0) /* ETH */] -= _amount;
        _to.transfer(_amount);
        emit ReleasedEth(_to, _amount);
    }

    function _receiveToken(address _from, address _token, uint256 _amount) internal {
        require(_amount > 0, "Treasury: Cannot receive 0 tokens");
        balances[_token] += _amount;
        emit ReceivedToken(_from, _token, _amount);
    }

    function _receiveEth(address _from, uint256 _amount) internal {
        require(_amount > 0, "Treasury: Cannot receive 0 ETH");
        balances[address(0) /* ETH */] += _amount;
        emit ReceivedEth(_from, _amount);
    }

    receive() payable external {
        _receiveEth(tx.origin, msg.value);
    }

    fallback() payable external {
        if (msg.value > 0){
            _receiveEth(tx.origin, msg.value);
        }else{
            revert("Treasury: Cannot receive tokens via fallback");
        }
        
    }


}

