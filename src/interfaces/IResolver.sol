// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

interface IResolver {
    function getUserSettings(address safe)
        external
        view
        returns (uint256 service, uint256 spendLimit, address originalSafe, address connectedSafe);
}
