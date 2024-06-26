pragma solidity ^0.8.20;

/**
 * @title IAllowanceOracle
 * @notice Defines the basic interface for an IAllowanceOracle
 */
interface IAllowanceOracle {
    function decreaseAllowance(address safe, uint256 amount) external;
    function increaseAllowance(address safe, uint256 amount) external;
    function canSafePay(address safe, uint256 amount) external view returns (bool);
}
