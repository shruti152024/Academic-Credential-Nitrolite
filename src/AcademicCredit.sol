// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract AcademicCredit is ERC20, AccessControl {

    bytes32 public constant CREDIT_ISSUER_ROLE =
        keccak256("CREDIT_ISSUER_ROLE");

    constructor(address universityAdmin)
        ERC20("Academic Credit Token", "ACREDIT")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, universityAdmin);
        _grantRole(CREDIT_ISSUER_ROLE, universityAdmin);
    }
event CreditsIssued(
    address indexed student,
    uint256 credits
);

event CreditsRevoked(
    address indexed student,
    uint256 credits
);
function issueCredits(
    address student,
    uint256 credits
)
    external
    onlyRole(CREDIT_ISSUER_ROLE)
{
    require(student != address(0), "Invalid student");
    require(student.code.length == 0, "Contracts not allowed");
    require(credits > 0, "Zero credits");

    _mint(student, credits);

    emit CreditsIssued(student, credits);
}
function revokeCredits(
    address student,
    uint256 credits
)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
{
    require(student != address(0), "Invalid student");
    require(balanceOf(student) >= credits, "Insufficient credits");

    _burn(student, credits);

    emit CreditsRevoked(student, credits);
}
function _update(
    address from,
    address to,
    uint256 value
)
    internal
    override
{
    if (from != address(0) && to != address(0)) {
        revert("Academic credits are non-transferable");
    }

    super._update(from, to, value);
}
function supportsInterface(bytes4 interfaceId)
    public
    view
    override(AccessControl)
    returns (bool)
{
    return super.supportsInterface(interfaceId);
}
}