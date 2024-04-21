// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;
//

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { console2 } from "forge-std/src/console2.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { Resolver } from "../src/sign_resolver/Resolver.sol";
//
//import { CreditModule } from "../src/CreditModule.sol";
//import { LendingPoolMock } from "../src/LendingPoolMock.sol";
//import { ERC20 } from "@solmate/src/tokens/ERC20.sol";
//import { SafeTransferLib } from "@solmate/src/utils/SafeTransferLib.sol";
//

contract ResolverTest is PRBTest, StdCheats {
    Resolver public resolver;

    function setUp() public virtual {
        // Instantiate contracts
        resolver = new Resolver();
    }

    function testFuzz_Resolver() external {
        address attester = 0xbCc802BFb35C4CDC9cA1B3e0bc0EbfEf7d0DcDb1;
        uint64 schemaId = 0x7;
        uint64 attestationId = 0;
        uint256 service = 1;
        uint256 limit = 5100;
        address originalSafe = 0xbCc802BFb35C4CDC9cA1B3e0bc0EbfEf7d0DcDb1;
        address connectedSafe = 0xbCc802BFb35C4CDC9cA1B3e0bc0EbfEf7d0DcDb1;

        bytes memory extraData;
        bytes memory encodedData = abi.encode(service, limit, originalSafe, connectedSafe);
        //        extraData =
        // 0x000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000013ec000000000000000000000000bcc802bfb35c4cdc9ca1b3e0bc0ebfef7d0dcdb1000000000000000000000000bcc802bfb35c4cdc9ca1b3e0bc0ebfef7d0dcdb1;
        //        encodData =
        // 0x000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000013ec000000000000000000000000bcc802bfb35c4cdc9ca1b3e0bc0ebfef7d0dcdb1000000000000000000000000bcc802bfb35c4cdc9ca1b3e0bc0ebfef7d0dcdb1
        //        assertEq(extraData, encodedData);
        emit LogBytes(encodedData);
        resolver.didReceiveAttestation(attester, schemaId, attestationId, encodedData);
    }
}

//Resolver internal resolver;
//CreditModule internal creditModule;
//LendingPoolMock internal lendingPool;
//
//address public oracleStETH =
//contract CreditModuleTest is PRBTest, StdCheats {
//    CreditModule internal creditModule;
//    LendingPoolMock internal lendingPool;
//
//    address public oracleStETH = 0x229e486Ee0D35b7A9f668d10a1e6029eEE6B77E0;
//    address public oracleEURe = 0xab70BCB260073d036d1660201e9d5405F5829b7a;
//    address public stETH = 0x6C76971f98945AE98dD7d4DFcA8711ebea946eA6;
//    address public EURe = 0xcB444e90D8198415266c6a2724b7900fb12FC56E;
//
//    // Helper function
//    function createUser(string memory name) internal returns (address payable) {
//        address payable user = payable(makeAddr(name));
//        vm.deal({ account: user, newBalance: 100 ether });
//        return user;
//    }
//
//    /// @dev A function invoked before each test case is run.
//    function setUp() public virtual {
//        // Instantiate contracts
//        lendingPool = new LendingPoolMock(EURe, "LendingPool", "LP", stETH, oracleEURe, oracleStETH);
//        creditModule = new CreditModule(oracleStETH, oracleEURe, stETH, EURe, address(lendingPool));
//        lendingPool.setCreditModule(address(creditModule));
//    }
//
//    function testFuzz_CreditModule_conversionRate() external {
//        uint256 conversionRate = creditModule.getConversionRateStETHToEur();
//
//        emit LogNamedUint256("Conversion rate stETH/EUR", conversionRate);
//    }
//
//    function testFuzz_canSafePay() public {
//        // Create users
//        address safe = createUser("safe");
//        address lp = createUser("lp");
//
//        uint256 lpAmount = 3000 * 1e18;
//
//        vm.prank(balancerVault);
//        ERC20(EURe).transfer(lp, lpAmount);
//
//        vm.startPrank(lp);
//        ERC20(EURe).approve(address(lendingPool), lpAmount);
//        lendingPool.deposit(lpAmount, lp);
//
//        // deal stETH to safe
//        deal(stETH, safe, 1 * 1e18);
//
//        (bool canPay, address currency,) = creditModule.canSafePay(safe, 1000 * 1e18);
//
//        assertEq(canPay, true);
//        assertEq(currency, stETH);
//    }
//
//    function testFuzz_borrowFor() public {
//        // Create users
//        address safe = createUser("safe");
//        address lp = createUser("lp");
//        address visa = createUser("visa");
//
//        uint256 lpAmount = 3000 * 1e18;
//        uint256 collateralAmount = 1 * 1e18;
//        uint256 amountToPay = 1000 * 1e18;
//
//        // safe should give approval to Credit Module
//        vm.prank(safe);
//        ERC20(stETH).approve(address(creditModule), type(uint256).max);
//
//        vm.prank(balancerVault);
//        ERC20(EURe).transfer(lp, lpAmount);
//
//        vm.startPrank(lp);
//        ERC20(EURe).approve(address(lendingPool), lpAmount);
//        lendingPool.deposit(lpAmount, lp);
//
//        // deal stETH to safe
//        deal(stETH, safe, collateralAmount);
//
//        (bool canPay, address currency, uint256 conversionRate) = creditModule.canSafePay(safe, amountToPay);
//
//        assertEq(canPay, true);
//        assertEq(currency, stETH);
//
//        // If safe can pay, borrow for safe
//        creditModule.pay(safe, amountToPay, currency, visa, conversionRate);
//    }
//}
