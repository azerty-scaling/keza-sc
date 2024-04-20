// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { KMessage } from "../interfaces/IKMessage.sol";
import { Owned } from "@solmate/src/auth/Owned.sol";
import { ERC4626 } from "@solmate/src/mixins/ERC4626.sol";
import { ERC20 } from "@solmate/src/tokens/ERC20.sol";
import { IStrategy } from "../interfaces/IStrategy.sol";
import { IStrategyToken } from "../interfaces/IStrategyToken.sol";
import { FixedPointMathLib } from "@solmate/src/utils/FixedPointMathLib.sol";
import { IYaru } from "../interfaces/IYaru.sol";
import { SafeTransferLib } from "@solmate/src/utils/SafeTransferLib.sol";

contract StrategyLock is ERC4626, Owned {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    /* //////////////////////////////////////////////////////////////
                               ERRORS
    ////////////////////////////////////////////////////////////// */
    error NotLockRouter(address sender, address expectedRouter);
    error MessageAlreadyProcessed(KMessage message);
    error NotYaru(address caller, address expectedYaru);

    /* //////////////////////////////////////////////////////////////
                               EVENTS
    ////////////////////////////////////////////////////////////// */

    event MessageProcessed(KMessage);

    /* //////////////////////////////////////////////////////////////
                               CONSTANTS
    ////////////////////////////////////////////////////////////// */
    uint16 public constant LOCK = 1;
    uint16 public constant UNLOCK = 2;

    address public YARU;
    address public LOCK_ROUTER;

    IStrategyToken public immutable STRATEGY_TOKEN;
    IStrategy public immutable STRATEGY;

    /* //////////////////////////////////////////////////////////////
                               STORAGE
    ////////////////////////////////////////////////////////////// */

    mapping(bytes32 => bool) private _processedMessages;
    mapping(address => uint256) public lockedAmount;
    mapping(address => uint256) public initialDepositAmount;

    /* //////////////////////////////////////////////////////////////
                               CONSTRUCT
    ////////////////////////////////////////////////////////////// */

    constructor(
        address underlyingAsset_,
        string memory name_,
        string memory symbol_,
        address yaru,
        address lockRouter,
        address strategyToken
    )
        ERC4626(ERC20(underlyingAsset_), name_, symbol_)
        Owned(msg.sender)
    {
        YARU = yaru;
        LOCK_ROUTER = lockRouter;
        STRATEGY_TOKEN = IStrategyToken(strategyToken);
        STRATEGY = IStrategy(IStrategyToken(strategyToken).POOL());
    }

    /* //////////////////////////////////////////////////////////////
                               ADMIN
    ////////////////////////////////////////////////////////////// */

    function setLockRouter(address lockRouter) external onlyOwner {
        LOCK_ROUTER = lockRouter;
    }

    function setYaru(address yaru) external onlyOwner {
        YARU = yaru;
    }

    function refund(address token, address receiver) public {
        uint256 strategyTokenBalance = STRATEGY_TOKEN.balanceOf(address(this));
        STRATEGY.withdraw(address(asset), strategyTokenBalance, address(this));

        uint256 balance = ERC20(token).balanceOf(address(this));
        if (balance > 0) {
            ERC20(token).transfer(receiver, balance);
        }
    }

    /* //////////////////////////////////////////////////////////////
                               HELPERS
    ////////////////////////////////////////////////////////////// */

    function getMessageId(KMessage calldata message) public pure returns (bytes32) {
        return keccak256(abi.encode(message));
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

    /* //////////////////////////////////////////////////////////////
                         CROSS CHAIN LOGIC
    ////////////////////////////////////////////////////////////// */

    function onMessage(KMessage calldata message) external {
        if (msg.sender != YARU) revert NotYaru(msg.sender, YARU);
        address router = IYaru(YARU).sender();
        if (router != LOCK_ROUTER) revert NotLockRouter(router, LOCK_ROUTER);

        bytes32 messageId = getMessageId(message);
        if (_processedMessages[messageId]) revert MessageAlreadyProcessed(message);
        _processedMessages[messageId] = true;

        if (message.action == LOCK) {
            _lock(message.to, message.amount);
        } else if (message.action == UNLOCK) {
            _unlock(message.to, message.amount);
        }

        emit MessageProcessed(message);
    }

    function _lock(address owner, uint256 amount) internal {
        require(initialDepositAmount[owner] - lockedAmount[owner] >= amount, "StrategyLock: Not enough shares to lock");
        lockedAmount[owner] += amount;
    }

    function _unlock(address owner, uint256 amount) internal {
        require(lockedAmount[owner] >= amount, "StrategyLock: Not enough locked amount");
        lockedAmount[owner] -= amount;
    }

    /* //////////////////////////////////////////////////////////////
                                  LOGIC
    ////////////////////////////////////////////////////////////// */

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);
        initialDepositAmount[receiver] += assets;

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        public
        virtual
        override
        returns (uint256 shares)
    {
        require(initialDepositAmount[owner] - lockedAmount[owner] >= assets, "Not enough shares to withdraw");

        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);
        initialDepositAmount[owner] -= assets;

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function totalAssets() public view override returns (uint256 assets) {
        assets = asset.balanceOf(address(this));
    }
}
