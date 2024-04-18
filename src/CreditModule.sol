// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IChainlinkData } from "./interfaces/IChainlinkData.sol";
import { ILendingPoolMock } from "./interfaces/ILendingPoolMock.sol";
import { IBalancerVault } from "./interfaces/IBalancerVault.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CreditModule {
    using SafeERC20 for ERC20;
    /* //////////////////////////////////////////////////////////////
                               CONSTANTS
    ////////////////////////////////////////////////////////////// */

    IChainlinkData public immutable STETH_USD_ORACLE;
    IChainlinkData public immutable EURE_USD_ORACLE;

    uint256 public daiOracleDecimals;
    uint256 public eureOracleDecimals;

    ERC4626 public immutable STETH;
    ERC20 public immutable EURE;

    address payable public eureVault;
    address public balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    uint256 public constant BIPS = 10_000;

    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    uint256 public vaultBalanceDiscountFactor;
    uint256 public fee;

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    event VaultRefunded(uint256 indexed sdaiReceived, uint256 indexed eureRefunded);
    event PaidForSafe(address indexed safe, uint256 indexed amount, address indexed to);

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    constructor(address oracleStETH, address oracleEURe, address stETH, address EURe_) {
        STETH_USD_ORACLE = IChainlinkData(oracleStETH);
        EURE_USD_ORACLE = IChainlinkData(oracleEURe);

        daiOracleDecimals = 10 ** STETH_USD_ORACLE.decimals();
        eureOracleDecimals = 10 ** EURE_USD_ORACLE.decimals();

        STETH = ERC20(stETH);
        EURE = ERC20(EURe_);

        fee = 100;
    }

    /* //////////////////////////////////////////////////////////////
                                LOGIC
    ////////////////////////////////////////////////////////////// */

    function getConversionRateStETHToEur() public view returns (uint256 conversionRate) {
        (, int256 stETHUSD,,,) = STETH_USD_ORACLE.latestRoundData();
        (, int256 EUReUSD,,,) = EURE_USD_ORACLE.latestRoundData();
        conversionRate = (stETHUSD * EUReUSD) / eureOracleDecimals;
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
        if (EUR_E.balanceOf(safe) >= amount) return (true, address(EUR_E), 0);

        // If enough SDAI balance in Safe to repay at current rate and CreditModule holds enough funds =>  CreditModule
        // will advance the EURe.
        uint256 sdaiBalance = S_DAI.balanceOf(safe);
        uint256 sdaiToEureRate = getConversionRateSDaiToEur();
        uint256 eureAmount = (sdaiBalance * sdaiToEureRate) / 1e18;

        // Calculate fee, Safe should also be able to pay back the fee
        uint256 eureAmountToSDai = (amount * 1e18) / sdaiToEureRate;
        uint256 fee_ = (fee * eureAmountToSDai) / BIPS;
        if (sdaiBalance < eureAmountToSDai + fee_) return (false, address(0), 0);

        uint256 eureAvailableInVault = EUR_E.balanceOf(eureVault);
        uint256 eureDiscountedAmount = eureAvailableInVault * vaultBalanceDiscountFactor / BIPS;

        if (eureAmount >= amount && eureDiscountedAmount >= amount) return (true, address(S_DAI), sdaiToEureRate);

        // If none of the above valid, Safe can't pay.
        return (false, address(0), 0);
    }

    function pay(address safe, uint256 amount, address currency, address to, uint256 conversionRate) external {
        if (currency == address(EUR_E)) _payThroughSafe(safe, amount, to);
        if (currency == address(S_DAI)) _payThroughCreditModule(safe, amount, to, conversionRate);
    }

    function _payThroughSafe(address safe, uint256 amount, address to) internal {
        EUR_E.safeTransferFrom(safe, to, amount);
    }

    function _payThroughCreditModule(address safe, uint256 amount, address to, uint256 conversionRate) internal {
        // Get EURe from the Vault
        IVault(eureVault).flashCredit(amount);

        // Pay with EURe for the Safe
        EUR_E.transfer(to, amount);

        emit PaidForSafe(safe, amount, to);

        // Get SDAI + fee from the Safe
        uint256 eureAmountToSDai = (amount * 1e18) / conversionRate;
        uint256 fee_ = (fee * eureAmountToSDai) / BIPS;
        uint256 sdaiAmountWithFee = eureAmountToSDai + fee_;

        S_DAI.transferFrom(safe, address(this), sdaiAmountWithFee);

        // Swap SDAI to EURe
        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap({
            poolId: 0xdd439304a77f54b1f7854751ac1169b279591ef7000000000000000000000064,
            kind: IBalancerVault.SwapKind.GIVEN_IN,
            assetIn: address(S_DAI),
            assetOut: address(EUR_E),
            amount: sdaiAmountWithFee,
            userData: ""
        });

        // Amount is swapped directly to Vault
        IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: eureVault,
            toInternalBalance: false
        });

        S_DAI.approve(balancerVault, sdaiAmountWithFee);
        uint256 eureRefunded = IBalancerVault(balancerVault).swap(singleSwap, funds, 0, block.timestamp);

        emit VaultRefunded(sdaiAmountWithFee, eureRefunded);
    }

    /* //////////////////////////////////////////////////////////////
                                LOGIC
    ////////////////////////////////////////////////////////////// */
    function setEureVault(address eureVault_) external {
        eureVault = payable(eureVault_);
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
