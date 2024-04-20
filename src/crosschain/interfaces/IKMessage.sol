pragma solidity ^0.8.17;

struct KMessage {
    bytes32 salt;
    uint16 action;
    address to;
    uint256 amount;
}
