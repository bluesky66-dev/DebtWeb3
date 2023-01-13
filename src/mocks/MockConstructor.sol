// // SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {FreeDebtNFT} from "../tokens/FreeDebtNFT.sol";

import {CoreComponents} from "../lib/CoreComponents.sol";
import {Events} from "../lib/Events.sol";
import {Errors} from "../lib/Errors.sol";

contract Constructor {

    CoreComponents.LineOfDebt[] public linesOfDebt;

    FreeDebtNFT fdnft;

    address core;
    address coop;
    address treasury;

    constructor(address _fdnft, address _core, address _coop, address _treasury) {
        fdnft = FreeDebtNFT(_fdnft);
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
        ) internal pure returns(CoreComponents.AgeRange, CoreComponents.IncomeBracket, CoreComponents.DebtType, CoreComponents.DebtStatus, CoreComponents.DebtPaymentStatus, CoreComponents.DebtWipeStatus) {
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
    ) external returns(uint256) {

        (CoreComponents.AgeRange ageRange, CoreComponents.IncomeBracket incomeBracket,
        CoreComponents.DebtType debtType, CoreComponents.DebtStatus debtStatus,
        CoreComponents.DebtPaymentStatus debtPaymentStatus, CoreComponents.DebtWipeStatus debtWipeStatus) = metadataLOD(
        _AgeRange, _IncomeBracket, _DebtType, _DebtStatus, _DebtPaymentStatus, _DebtWipeStatus);

        bytes memory infos = abi.encodePacked(_DebtAmount, _DebtInterest, _DebtDuration, _DebtPurchasePrice, _DebtPurchaseDate,  ageRange, incomeBracket, debtType, debtStatus, debtPaymentStatus, debtWipeStatus);
        uint256 id = _tokeniseInfo(infos);
        return id;

    }

    function _tokeniseInfo(bytes memory _infos) internal returns(uint256) {

            (uint256 _DebtAmount, uint256 _DebtInterest, uint256 _DebtDuration, uint256 _DebtPurchasePrice, uint256 _DebtPurchaseDate,
             CoreComponents.AgeRange ageRange, CoreComponents.IncomeBracket incomeBracket,
        CoreComponents.DebtType debtType, CoreComponents.DebtStatus debtStatus,
        CoreComponents.DebtPaymentStatus debtPaymentStatus, CoreComponents.DebtWipeStatus debtWipeStatus, uint256 id) = abi.decode(_infos, (uint256, uint256, uint256, uint256, uint256, CoreComponents.AgeRange, CoreComponents.IncomeBracket, CoreComponents.DebtType, CoreComponents.DebtStatus, CoreComponents.DebtPaymentStatus, CoreComponents.DebtWipeStatus, uint256));

            CoreComponents.LineOfDebt memory lineOfDebt = CoreComponents.LineOfDebt(
            _DebtAmount, 
            _DebtInterest, 
            _DebtDuration, 
            _DebtPurchasePrice, 
            _DebtPurchaseDate,
            CoreComponents.DebtorInfo(
                ageRange, incomeBracket
            ),
            debtType,
            debtStatus,
            debtPaymentStatus,
            debtWipeStatus
        );

        linesOfDebt.push(lineOfDebt);

        fdnft.safeMint(address(this), 'uri', lineOfDebt);
        emit Events.TokenisedLOD(msg.sender, id, lineOfDebt.DebtDuration, lineOfDebt.DebtAmount);
        return id;
    }

    function _tokenise(
        uint256 tokenId,
        CoreComponents.AgeRange ageRange, CoreComponents.IncomeBracket incomeBracket,
        CoreComponents.DebtType debtType, CoreComponents.DebtStatus debtStatus,
        CoreComponents.DebtPaymentStatus debtPaymentStatus, CoreComponents.DebtWipeStatus debtWipeStatus) internal {

        CoreComponents.LineOfDebt storage lineOfDebt = linesOfDebt[tokenId];

        lineOfDebt.DebtorInfo.AgeRange = ageRange;
        lineOfDebt.DebtorInfo.IncomeBracket = incomeBracket;
        lineOfDebt.DebtType = debtType;
        lineOfDebt.DebtStatus = debtStatus;
        lineOfDebt.DebtPaymentStatus = debtPaymentStatus;
        lineOfDebt.DebtWipeStatus = debtWipeStatus;

       
        }

    function getLOD(address _owner, uint256 _id) public view returns (CoreComponents.LineOfDebt memory) {
        uint256 tokenId = fdnft.tokenOfOwnerByIndex(_owner, _id);
        return linesOfDebt[tokenId];
    }

    function tokenisedLODs() public view returns (CoreComponents.LineOfDebt[] memory) {
        return linesOfDebt;
    }
}