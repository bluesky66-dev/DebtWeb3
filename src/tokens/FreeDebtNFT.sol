// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin-upgrades/contracts/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin-upgrades/contracts/token/ERC721/extensions/draft-ERC721VotesUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/utils/CountersUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {CoreComponents} from "../CoreComponents.sol";

/// @custom:security-contact Keyrxng@proton.me
contract FreeDebtNFT is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, EIP712Upgradeable, ERC721VotesUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using Strings for uint256;
    using String for uint8;

    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("FreeDebtNFT", "MTK");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __EIP712_init("FreeDebtNFT", "1");
        __ERC721Votes_init();
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://testtesttesttest";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal pure virtual override returns (string memory) {
        return _baseTokenURI();
    }

    function 

    function safeMint(address to, string memory uri, CoreComponents.LineOfDebt _lod) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Upgradeable, ERC721VotesUpgradeable)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        bytes memory dataURI = abi.encodePacked(
            "data:application/json,", '{'
            '"name": "Token Name",'
            '"description": "Token Description",'
            '"image": "testtesttest",'
            '"attributes": ['
                '{"trait_type": "Strength", "value": 10},'
                '{"trait_type": "Defense", "value": 20},'
                '{"trait_type": "Level", "value": 3000}'
            ']}'
        );
        string memory uri = string(dataURI);
        return uri;


        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}