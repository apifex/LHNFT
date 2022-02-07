// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT_internal.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IERC2981.sol";

// royalties -> 1eth -> 10%

// Fixed royalties — this is expected to be the common case where a static percentage is used for every sale.
// Decaying royalties — reduce royalties owed for every transfer event of the NFT over time.
// Multisig royalties — the receiver address could be a multisig smart contract. It may represent a DAO or some effort towards public goods funding.
// Stepped royalties — don’t send royalties if the sale price is below a threshold.

abstract contract NFT_Royalties is IERC2981 {
    mapping(uint256 => RoyaltyInfo) internal _royalties;

    struct RoyaltyInfo {
        address receiver;
        uint256 amount;
    }

    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint256 value
    ) internal {
        require(value <= 10000, "Royalties too high");
        _royalties[tokenId] = RoyaltyInfo(receiver, value);
    }

    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties[tokenId];
        receiver = royalties.receiver;
        royaltyAmount = (value * royalties.amount) / 10000;
    }
}
