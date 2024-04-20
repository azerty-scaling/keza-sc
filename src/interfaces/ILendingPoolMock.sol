// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

interface ILendingPool {
    function collateralFactor() external view returns (uint256);
    function borrowFor(address borrower, uint256 amountToBorrow, uint256 collateralAmount) external;
}
