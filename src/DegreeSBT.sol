// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract DegreeSBT is ERC721, AccessControl {

    bytes32 public constant DEGREE_ISSUER_ROLE =
        keccak256("DEGREE_ISSUER_ROLE");

    constructor(address universityAdmin)
        ERC721("Academic Degree", "DEGREE")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, universityAdmin);
        _grantRole(DEGREE_ISSUER_ROLE, universityAdmin);
    }

    mapping(address => bool) public hasDegree;

    event DegreeIssued(
        address indexed student,
        uint256 indexed tokenId
    );

    event DegreeRevoked(
        address indexed student,
        uint256 indexed tokenId
    );
    function issueDegree(
    address student,
    uint256 tokenId
)
    external
    onlyRole(DEGREE_ISSUER_ROLE)
{
    require(student != address(0), "Invalid student");
    require(student.code.length == 0, "Contracts not allowed");
    require(!hasDegree[student], "Degree already issued");

    hasDegree[student] = true;

    _safeMint(student, tokenId);

    emit DegreeIssued(student, tokenId);
}
function revokeDegree(
    uint256 tokenId
)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
{
    address student = ownerOf(tokenId);

    hasDegree[student] = false;

    _burn(tokenId);

    emit DegreeRevoked(student, tokenId);
}
    function _update(
    address to,
    uint256 tokenId,
    address auth
)
    internal
    override
    returns (address)
{
    address from = _ownerOf(tokenId);

    if (from != address(0) && to != address(0)) {
        revert("Soulbound: transfer not allowed");
    }

    return super._update(to, tokenId, auth);
}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}