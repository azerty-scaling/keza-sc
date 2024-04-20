// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IChainlinkData } from "./interfaces/IChainlinkData.sol";
import { ILendingPool } from "./interfaces/ILendingPoolMock.sol";
import { IBalancerVault } from "./interfaces/IBalancerVault.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CreditModule {
    using SafeERC20 for ERC20;
    /* //////////////////////////////////////////////////////////////
                               CONSTANTS
    ////////////////////////////////////////////////////////////// */

    IChainlinkData public immutable STETH_USD_ORACLE;
    IChainlinkData public immutable EURE_USD_ORACLE;

    uint256 public oracleDecimals;

    ERC20 public immutable STETH;
    ERC20 public immutable EURE;

    address public lendingPool;
    address public balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    uint256 public constant BIPS = 10_000;

    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    uint256 public fee;

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    event PaidForSafe(address indexed safe, uint256 indexed amount, address indexed to);

    /* //////////////////////////////////////////////////////////////
                                ERRORS
    ////////////////////////////////////////////////////////////// */

    error NotEnoughFundsInLP();

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    constructor(address oracleStETH, address oracleEURe, address stETH, address EURe_, address lendingPool_) {
        STETH_USD_ORACLE = IChainlinkData(oracleStETH);
        EURE_USD_ORACLE = IChainlinkData(oracleEURe);

        // They both have 8 decimals precision
        oracleDecimals = 10 ** STETH_USD_ORACLE.decimals();

        STETH = ERC20(stETH);
        EURE = ERC20(EURe_);

        lendingPool = lendingPool_;

        fee = 100;
    }

    /* //////////////////////////////////////////////////////////////
                                LOGIC
    ////////////////////////////////////////////////////////////// */

    function getConversionRateStETHToEur() public view returns (uint256 conversionRate) {
        // Both oracles have 8 decimals precision
        (, int256 stETHUSD,,,) = STETH_USD_ORACLE.latestRoundData();
        (, int256 EUReUSD,,,) = EURE_USD_ORACLE.latestRoundData();
        conversionRate = (uint256(stETHUSD) * oracleDecimals) / uint256(EUReUSD);
    }

    function canSafePay(
        address safe,
        uint256 amount
    )
        external
        view
        returns (bool canPay, address currency, uint256 conversionRate)
    {
        // Pay directly with EURe if enough balance
        if (EURE.balanceOf(safe) >= amount) return (true, address(EURE), 0);

        // Revert if not enough available liquidity in lending pool
        if (EURE.balanceOf(lendingPool) < amount) return (false, address(0), 0);

        // If enough STETH balance in Safe to borrow at current rate and LendingPool holds enough funds => Borrow EURe
        uint256 stETHBalance = STETH.balanceOf(safe);
        uint256 stETHToEureRate = getConversionRateStETHToEur();
        uint256 eureValue = stETHBalance * stETHToEureRate / oracleDecimals;

        // Discount the eureValue with collateral factor of lendingPool
        uint256 borrowableEurE = eureValue * ILendingPool(lendingPool).collateralFactor() / BIPS;
        if (borrowableEurE < amount) return (false, address(0), 0);

        if (borrowableEurE >= amount) return (true, address(STETH), stETHToEureRate);

        // If none of the above valid, Safe can't pay.
        return (false, address(0), 0);
    }

    function pay(address safe, uint256 amount, address currency, address to, uint256 conversionRate) external {
        if (currency == address(EURE)) _payThroughSafe(safe, amount, to);
        if (currency == address(STETH)) _payThroughCreditModule(safe, amount, to, conversionRate);
    }

    function _payThroughSafe(address safe, uint256 amount, address to) internal {
        EURE.safeTransferFrom(safe, to, amount);
    }

    function _payThroughCreditModule(address safe, uint256 amount, address to, uint256 conversionRate) internal {
        uint256 collateralFactor = BIPS * BIPS / ILendingPool(lendingPool).collateralFactor();
        uint256 collateralAmount = (collateralFactor * (amount * oracleDecimals / conversionRate) / BIPS);

        STETH.transferFrom(safe, address(this), collateralAmount);
        STETH.approve(lendingPool, collateralAmount);

        // Get EURe from the Vault
        ILendingPool(lendingPool).borrowFor(safe, amount, collateralAmount);

        // Pay with EURe for the Safe
        EURE.transfer(to, amount);

        emit PaidForSafe(safe, amount, to);
    }

    /* //////////////////////////////////////////////////////////////
                                LOGIC
    ////////////////////////////////////////////////////////////// */
    function setLendingPool(address lendingPool_) external {
        lendingPool = lendingPool_;
    }

    function setFee(uint256 newFee) external {
        fee = newFee;
    }

    function refund(address token, address receiver) public {
        uint256 balance = ERC20(token).balanceOf(address(this));
        if (balance > 0) {
            ERC20(token).transfer(receiver, balance);
        }
    }
}
