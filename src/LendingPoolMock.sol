// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import "./interfaces/IChainlinkData.sol";
import { Owned } from "@solmate/src/auth/Owned.sol";
import { ERC4626 } from "@solmate/src/mixins/ERC4626.sol";
import { ERC20 } from "@solmate/src/tokens/ERC20.sol";
import { FixedPointMathLib } from "@solmate/src/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "@solmate/src/utils/SafeTransferLib.sol";

contract LendingPoolMock is ERC4626, Owned {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    /* //////////////////////////////////////////////////////////////
                                CONSTANTS
    ////////////////////////////////////////////////////////////// */

    address public CREDIT_MODULE;
    address public EUR_ORACLE;
    address public STETH_ORACLE;

    ERC20 public immutable STETH;
    
    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    mapping(address borrower => uint256 debt) public debtBorrower;
    mapping(address borrower => uint256 collateral) public collateralBorrower;

    // Collateral factor in BIPS
    uint256 public collateralFactor = 5000;
    uint256 public totalBorrowed;
    uint256 public fee = 100;
    uint256 public BIPS = 10_000;

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    /* //////////////////////////////////////////////////////////////
                                ERRORS
    ////////////////////////////////////////////////////////////// */

    error NotEnoughFunds();
    error CollateralValueTooLow();
    error NoRemainingDebt();

    /* //////////////////////////////////////////////////////////////
                                MODIFIERS
    ////////////////////////////////////////////////////////////// */

    modifier onlyCreditModule() {
        require(msg.sender == CREDIT_MODULE, "LendingPool: Only Credit Module can call this function");
        _;
    }

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */
    constructor(
        address underlyingAsset_,
        string memory name_,
        string memory symbol_,
        address stETH,
        address eurOracle,
        address stETHOracle
    )
        ERC4626(ERC20(underlyingAsset_), name_, symbol_)
        Owned(msg.sender)
    {
        STETH = ERC20(stETH);
        EUR_ORACLE = eurOracle;
        STETH_ORACLE = stETHOracle;
    }

    /* //////////////////////////////////////////////////////////////
                                LOGIC
    ////////////////////////////////////////////////////////////// */

    function borrowFor(address borrower, uint256 amountToBorrow, uint256 collateralAmount) public onlyCreditModule {
        if (totalAssets() - totalBorrowed < amountToBorrow) revert NotEnoughFunds();

        (, int256 rateCollateralUsd ,,,) = IChainlinkData(STETH_ORACLE).latestRoundData();
        (, int256 rateEurUsd ,,,) = IChainlinkData(EUR_ORACLE).latestRoundData();

        // In 18 decimals
        uint256 collateralValueInUsd = uint256(rateCollateralUsd) * collateralAmount / IChainlinkData(STETH_ORACLE).decimals();
        // In 18 decimals
        uint256 collateralValueInEur = collateralValueInUsd * uint256(rateEurUsd) / IChainlinkData(EUR_ORACLE).decimals();
        // Discounted value 
        uint256 discountedCollateralValue = collateralValueInEur * collateralFactor / BIPS;

        if (amountToBorrow > discountedCollateralValue) revert CollateralValueTooLow();

        // Update accounting of borrowed amount
        totalBorrowed += amountToBorrow;

        // Update accounting for borrower
        uint256 fee_ = amountToBorrow * fee / BIPS;
        debtBorrower[borrower] += amountToBorrow + fee_;
        collateralBorrower[borrower] += collateralAmount;

        // Transfer assets to Credit Module
        asset.safeTransfer(msg.sender, amountToBorrow);
    }

    function reimburse(uint256 debtAmount) external {
        uint256 openDebt = debtBorrower[msg.sender];
        if (openDebt == 0) revert NoRemainingDebt();

        uint256 collateralRetrieved = debtAmount * collateralBorrower[msg.sender] / openDebt;

        // Get EURe with fees proportional to amount reimbursed 
        asset.safeTransferFrom(msg.sender, address(this), debtAmount);
        // Send proportional collateral back to msg.sender
        STETH.safeTransfer(msg.sender, collateralRetrieved);

        // Update accounting for borrower
        debtBorrower[msg.sender] -= debtAmount;
        collateralBorrower[msg.sender] -= collateralRetrieved;

        // Decrease totalBorrowed 
        // TODO: remove fee part (we are decreasing too much here)
        totalBorrowed -= debtAmount;
    }

    // TODO: If not paying after certain amount of time => then can take the funds back, sell them and reimburse the pool.

    function setCreditModule(address creditModule) external onlyOwner {
        CREDIT_MODULE = creditModule;
    }

    function refund(address token, address receiver) public {
        uint256 balance = ERC20(token).balanceOf(address(this));
        if (balance > 0) {
            ERC20(token).transfer(receiver, balance);
        }
    }

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this)) + totalBorrowed;
    }

    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////

    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        // Cache totalSupply.
        uint256 supply = totalSupply;

        shares = supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
        // Cache totalSupply.
        uint256 supply = totalSupply;

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////

    function previewDeposit(uint256 assets) public view override returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view override returns (uint256 assets) {
        // Cache totalSupply.
        uint256 supply = totalSupply;

        assets = supply == 0 ? shares : assets.mulDivUp(supply, totalAssets());
    }

    function previewWithdraw(uint256 assets) public view override returns (uint256 shares) {
        // Cache totalSupply.
        uint256 supply = totalSupply;

        shares = supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view override returns (uint256) {
        return convertToAssets(shares);
    }

    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");
    
        // Recalculate the assets
        assets = previewRedeem(shares);

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }
}
