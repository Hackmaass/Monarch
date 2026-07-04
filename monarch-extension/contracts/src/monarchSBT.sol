// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MonarchSBT
/// @notice Soulbound ERC-721 NFT for Monarch Proof of Competence
contract MonarchSBT is ERC721, Ownable {
    uint256 private _nextTokenId;

    // Mapping from token ID to evidence hash
    mapping(uint256 => bytes32) public evidenceHashes;
    // Mapping from token ID to token URI
    mapping(uint256 => string) private _tokenURIs;

    event CredentialMinted(uint256 indexed tokenId, address indexed recipient, bytes32 evidenceHash);
    error SoulboundTransferNotAllowed();

    constructor(address initialOwner)
        ERC721("Monarch Proof of Competence", "CRED")
        Ownable(initialOwner)
    {}

    function mint(
        address to,
        string calldata uri,
        bytes32 evidenceHash
    ) external onlyOwner returns (uint256 tokenId) {
        unchecked {
            tokenId = ++_nextTokenId;
        }

        evidenceHashes[tokenId] = evidenceHash;
        _tokenURIs[tokenId] = uri;

        _safeMint(to, tokenId);

        emit CredentialMinted(tokenId, to, evidenceHash);
    }

    function getEvidenceHash(uint256 tokenId) external view returns (bytes32) {
        _requireOwned(tokenId);
        return evidenceHashes[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenURIs[tokenId];
    }

    // --- Soulbound restrictions ---
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        address from = _ownerOf(tokenId);
        // Only allow minting (from == 0) and burning (to == 0)
        if (from != address(0) && to != address(0)) {
            revert SoulboundTransferNotAllowed();
        }
        return super._update(to, tokenId, auth);
    }
}
