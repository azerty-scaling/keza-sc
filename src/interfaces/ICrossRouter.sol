// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

interface ICrossRouter {
    function canSafePay(address safe, uint256 amount) external view returns (bool canPay);
    function pay(address safe, uint256 amount) external;
}
