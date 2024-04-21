// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISPHook } from "./interface/ISPHook.sol";

contract Resolver is ISPHook {
    event AttestationReceived(address attester, uint64 schemaId, uint64 attestationId);
    event AttestationReceived2(address originalSafe, uint256 service, uint256 limit);
    event Log(uint256 value);
    event Log2(bytes value);

    struct UserSettings {
        uint256 service;
        uint256 spendLimit;
        address originalSafe;
        address connectedSafe;
    }

    mapping(address => UserSettings) public userSettings;

    mapping(uint64 => bool) public attestationIdSent;

    function didReceiveAttestation(
        address attester,
        uint64 schemaId,
        uint64 attestationId,
        bytes calldata extraData
    )
        external
        payable
    {
        require(attestationIdSent[attestationId] == false, "Attestation already sent");
        attestationIdSent[attestationId] = true;

        UserSettings memory userSettings_;
        userSettings_ = abi.decode(extraData, (UserSettings));

        userSettings[userSettings_.originalSafe] = userSettings_;
        emit AttestationReceived(attester, schemaId, attestationId);
    }

    function didReceiveAttestation(
        address attester,
        uint64 schemaId,
        uint64 attestationId,
        IERC20 resolverFeeERC20Token,
        uint256 resolverFeeERC20Amount,
        bytes memory extraData
    )
        external
    {
        require(attestationIdSent[attestationId] == false, "Attestation already sent");
        attestationIdSent[attestationId] = true;

        UserSettings memory userSettings_;
        userSettings_ = abi.decode(extraData, (UserSettings));

        userSettings[userSettings_.originalSafe] = userSettings_;
        emit AttestationReceived(attester, schemaId, attestationId);
    }

    function didReceiveRevocation(
        address attester,
        uint64 schemaId,
        uint64 attestationId,
        bytes memory extraData
    )
        external
        payable
    {
        require(attestationIdSent[attestationId] == true, "Attestation not sent");
        attestationIdSent[attestationId] = false;

        UserSettings memory userSettings_;
        userSettings_ = abi.decode(extraData, (UserSettings));

        delete userSettings[userSettings_.originalSafe];
        emit AttestationReceived(attester, schemaId, attestationId);
    }

    function didReceiveRevocation(
        address attester,
        uint64 schemaId,
        uint64 attestationId,
        IERC20 resolverFeeERC20Token,
        uint256 resolverFeeERC20Amount,
        bytes calldata extraData
    )
        external
    {
        require(attestationIdSent[attestationId] == true, "Attestation not sent");
        attestationIdSent[attestationId] = false;

        UserSettings memory userSettings_;
        userSettings_ = abi.decode(extraData, (UserSettings));

        delete userSettings[userSettings_.originalSafe];
        emit AttestationReceived(attester, schemaId, attestationId);
    }

    function getUserSettings(address safe)
        external
        view
        returns (uint256 service, uint256 spendLimit, address originalSafe, address connectedSafe)
    {
        UserSettings memory settings = userSettings[safe];
        return (settings.service, settings.spendLimit, settings.originalSafe, settings.connectedSafe);
    }

    function addDummy(
        uint256 service,
        uint256 spendLimit,
        address originalSafe,
        address connectedSafe
    )
        external
        payable
    {
        userSettings[originalSafe] = UserSettings(service, spendLimit, originalSafe, connectedSafe);
        emit AttestationReceived2(originalSafe, service, spendLimit);
    }
}
