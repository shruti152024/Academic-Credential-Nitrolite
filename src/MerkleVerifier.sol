// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleVerifier is AccessControl {

    bytes32 public constant ROOT_ADMIN_ROLE =
        keccak256("ROOT_ADMIN_ROLE");
constructor(address universityAdmin)
{
    _grantRole(DEFAULT_ADMIN_ROLE, universityAdmin);
    _grantRole(ROOT_ADMIN_ROLE, universityAdmin);
}
bytes32 public merkleRoot;

event RootUpdated(
    bytes32 newRoot
);
function updateRoot(
    bytes32 newRoot
)
    external
    onlyRole(ROOT_ADMIN_ROLE)
{
    merkleRoot = newRoot;

    emit RootUpdated(newRoot);
}
function verifyCredential(
    bytes32[] calldata proof,
    bytes32 leaf
)
    external
    view
    returns (bool)
{
    return MerkleProof.verify(
        proof,
        merkleRoot,
        leaf
    );
}
function supportsInterface(bytes4 interfaceId)
    public
    view
    override
    returns (bool)
{
    return super.supportsInterface(interfaceId);
}
}