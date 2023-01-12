// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin-upgrades/contracts/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";

/// @custom:security-contact keyrxng@proton.me
contract DW3 is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    address core;
    address coop;
    address treasury;

    modifier authed() {
        require(msg.sender == core || msg.sender == coop || msg.sender == treasury, "DW3: only coop, core or treasury");
        _;
    }

    function initialize() initializer public {
        __ERC20_init("DebtWebFree", "DW3");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __ERC20Permit_init("DebtWebFree");
        __ERC20Votes_init();

        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function init(address _core, address _coop, address _treasury) public onlyOwner {
        require(_core != address(0), "DW3: invalid core address");
        require(_coop != address(0), "DW3: invalid coop address");
        require(_treasury != address(0), "DW3: invalid treasury address");
        core = _core;
        coop = _coop;
        treasury = _treasury;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public authed {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }
}