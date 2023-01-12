// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {FreeDebtNFT} from "./tokens/FreeDebtNFT.sol";

import {CoreComponents} from "./lib/CoreComponents.sol";
import {Events} from "./lib/Events.sol";
import {Errors} from "./lib/Errors.sol";

contract Constructor {

    CoreComponents.LineOfDebt[] public linesOfDebt;

    FreeDebtNFT fdnft;

    address core;
    address coop;
    address treasury;

    constructor(address _dfnft, address _core, address _coop, address _treasury) {
        dfnft = FreeDebtNFT(_dfnft);
        core = _core;
        coop = _coop;
        treasury = _treasury;
    }

    function metadataLOD(
        uint8 _ageRange,
        uint8 _incomeBracket,
        uint8 _debtType,
        uint8 _debtStatus,
        uint8 _debtPaymentStatus,
        uint8 _debtWipeStatus
        ) external pure returns(CoreComponents.AgeRange, CoreComponents.IncomeBracket, CoreComponents.DebtType, CoreComponents.DebtStatus, CoreComponents.DebtPaymentStatus, CoreComponents.DebtWipeStatus) {
        CoreComponents.AgeRange ageRange_ = CoreComponents.AgeRange(_ageRange);
        CoreComponents.IncomeBracket incomeBracket_ = CoreComponents.IncomeBracket(_incomeBracket);
        CoreComponents.DebtType debtType_ = CoreComponents.DebtType(_debtType);
        CoreComponents.DebtStatus debtStatus_ = CoreComponents.DebtStatus(_debtStatus);
        CoreComponents.DebtPaymentStatus debtPaymentStatus_ = CoreComponents.DebtPaymentStatus(_debtPaymentStatus);
        CoreComponents.DebtWipeStatus debtWipeStatus_ = CoreComponents.DebtWipeStatus(_debtWipeStatus);

        return (ageRange_, incomeBracket_, debtType_, debtStatus_, debtPaymentStatus_, debtWipeStatus_);
        }

    function tokeniseLOD(
        uint256 _DebtAmount, 
        uint256 _DebtInterest, 
        uint256 _DebtDuration, 
        uint256 _DebtPurchasePrice, 
        uint256 _DebtPurchaseDate,
        uint8  _AgeRange,
        uint8  _IncomeBracket,
        uint8  _DebtType,
        uint8  _DebtStatus,
        uint8  _DebtPaymentStatus,
        uint8  _DebtWipeStatus
    ) external {

        (CoreComponents.AgeRange ageRange, CoreComponents.IncomeBracket incomeBracket,
        CoreComponents.DebtType debtType, CoreComponents.DebtStatus debtStatus,
        CoreComponents.DebtPaymentStatus debtPaymentStatus, CoreComponents.DebtWipeStatus debtWipeStatus) = metadataLOD(
        _AgeRange, _IncomeBracket, _DebtType, _DebtStatus, _DebtPaymentStatus, _DebtWipeStatus);
        
        CoreComponents.LineOfDebt memory lineOfDebt = CoreComponents.LineOfDebt(
            _DebtAmount, 
            _DebtInterest, 
            _DebtDuration, 
            _DebtPurchasePrice, 
            _DebtPurchaseDate,
            CoreComponents.DebtorInfo({
                AgeRange: ageRange,
                IncomeBracket: incomeBracket
            }),
            debtType,
            debtStatus,
            debtPaymentStatus,
            debtWipeStatus
        );        
        linesOfDebt.push(lineOfDebt);


        uint id = linesOfDebt.length;
        string memory str = 'LineOfDebt' + string(id);

        uint256 tokenId = fdnft.safeMint(address(this), str);
        emit Events.TokenisedLOD(msg.sender, tokenId, _DebtDuration, _DebtAmount);

    }



    

    function getLOD(address owner) public view returns (CoreComponents.LineOfDebt memory) {
        uint256 tokenId = dfnft.tokenOfOwnerByIndex(owner);
        uint256 i = tokenId + 1;
        return linesOfDebt[i];
    }

    function tokenisedLODs() public view returns (CoreComponents.LineOfDebt[] memory) {
        return linesOfDebt;
    }


}