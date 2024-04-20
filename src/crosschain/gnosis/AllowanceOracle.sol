// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

contract AllowanceOracle {
    /* //////////////////////////////////////////////////////////////
                               CONSTANTS
    ////////////////////////////////////////////////////////////// */

    bytes32 public constant INCREASE = keccak256("INCREASE");
    bytes32 public constant DECREASE = keccak256("DECREASE");

    address public OFFCHAIN_ALLOWANCE_ORACLE;
    address public CREDIT_MODULE;
    address public CROSS_ROUTER;
    address public OWNER;

    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    mapping(address => uint256) public allowances;

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    event AllowanceIncrease(address indexed safe, uint256 indexed amount);
    event AllowanceDecrease(address indexed safe, uint256 indexed amount);

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    constructor(address offchainAllowanceOracle, address creditModule, address crossRouter) {
        OFFCHAIN_ALLOWANCE_ORACLE = offchainAllowanceOracle;
        CREDIT_MODULE = creditModule;
        CROSS_ROUTER = crossRouter;
    }

    modifier onlyOwner() {
        require(msg.sender == OWNER, "Only the owner can call this function");
        _;
    }

    modifier onlyTrustedParty() {
        require(
            msg.sender == OFFCHAIN_ALLOWANCE_ORACLE || msg.sender == CREDIT_MODULE || msg.sender == CROSS_ROUTER,
            "Only the trusted party oracle can call this function"
        );
        _;
    }

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    function setOffchainAllowanceOracle(address offchainAllowanceOracle) external onlyOwner {
        OFFCHAIN_ALLOWANCE_ORACLE = offchainAllowanceOracle;
    }

    function setCreditModule(address creditModule) external onlyOwner {
        CREDIT_MODULE = creditModule;
    }

    /* //////////////////////////////////////////////////////////////
                                LOGIC
    ////////////////////////////////////////////////////////////// */

    function canSafePay(address safe, uint256 amount) external view returns (bool canPay) {
        return allowances[safe] >= amount;
    }

    function decreaseAllowance(address safe, uint256 amount) external onlyTrustedParty {
        allowances[safe] -= amount;
        emit AllowanceDecrease(safe, amount);
    }

    function increaseAllowance(address safe, uint256 amount) external onlyTrustedParty {
        allowances[safe] += amount;
        emit AllowanceIncrease(safe, amount);
    }
}
