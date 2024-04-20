// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { KMessage } from "../interfaces/IKMessage.sol";
import { Message } from "hashi/packages/evm/contracts/interfaces/IMessage.sol";
import { IYaho } from "hashi/packages/evm/contracts/interfaces/IYaho.sol";
import { IAllowanceOracle } from "../interfaces/IAllowanceOracle.sol";

contract CrossRouter {
    event MessageDispatched(KMessage);

    /* //////////////////////////////////////////////////////////////
                               CONSTANTS
    ////////////////////////////////////////////////////////////// */
    uint16 public constant LOCK = 1;
    uint16 public constant UNLOCK = 2;

    uint16 public DESTINATION_CHAIN_ID = 42_161;

    /* //////////////////////////////////////////////////////////////
                               CONSTANTS
    ////////////////////////////////////////////////////////////// */
    address public YAHO;
    address public MESSAGE_RELAYER;
    address public ADAPTER;
    address public STRATEGY_LOCK;
    address public ALLOWANCE_ORACLE;

    /* //////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    constructor(address yaho, address messageRelayer, address adapter, address strategyLock, address allowanceOracle) {
        YAHO = yaho;
        MESSAGE_RELAYER = messageRelayer;
        ADAPTER = adapter;
        STRATEGY_LOCK = strategyLock;
        ALLOWANCE_ORACLE = allowanceOracle;
    }

    function canSafePay(address safe, uint256 amount) external view returns (bool canPay) {
        return IAllowanceOracle(ALLOWANCE_ORACLE).canSafePay(safe, amount);
    }

    function pay(address safe, uint256 amount) external {
        bytes32 salt = keccak256(abi.encodePacked(blockhash(block.number - 1), gasleft()));

        KMessage memory kMessage = KMessage({ salt: salt, action: LOCK, to: safe, amount: amount });
        bytes memory kData = abi.encodeWithSignature("onMessage((bytes32,uint16,address,uint256))", kMessage);

        address[] memory messageRelays = new address[](0);
        messageRelays[0] = MESSAGE_RELAYER;
        address[] memory adapters = new address[](0);
        adapters[0] = ADAPTER;

        Message[] memory messages = new Message[](1);
        messages[0] = Message(STRATEGY_LOCK, DESTINATION_CHAIN_ID, kData);

        IYaho(YAHO).dispatchMessagesToAdapters(messages, messageRelays, adapters);
        IAllowanceOracle(ALLOWANCE_ORACLE).decreaseAllowance(safe, amount);
        emit MessageDispatched(kMessage);
    }

    function payDebt(address safe, uint256 amount) external {
        bytes32 salt = keccak256(abi.encodePacked(blockhash(block.number - 1), gasleft()));

        KMessage memory kMessage = KMessage({ salt: salt, action: UNLOCK, to: safe, amount: amount });
        bytes memory kData = abi.encodeWithSignature("onMessage((bytes32,uint16,address,uint256))", kMessage);

        address[] memory messageRelays = new address[](0);
        messageRelays[0] = MESSAGE_RELAYER;
        address[] memory adapters = new address[](0);
        adapters[0] = ADAPTER;

        Message[] memory messages = new Message[](1);
        messages[0] = Message(STRATEGY_LOCK, DESTINATION_CHAIN_ID, kData);

        IYaho(YAHO).dispatchMessagesToAdapters(messages, messageRelays, adapters);
        IAllowanceOracle(ALLOWANCE_ORACLE).increaseAllowance(safe, amount);
        emit MessageDispatched(kMessage);
    }
}
