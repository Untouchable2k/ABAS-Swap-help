// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Ipool.sol";
import "./IBentoBoxV1.sol";
import "./IERC20.sol";


interface IWETH {
    function withdraw(uint256 amount) external;
    function deposit(uint256 amount) external;
}




contract ABAS_Swap {
    
  IBentoBoxV1 public constant bentobox = IBentoBoxV1(0x74c764D41B77DBbb4fe771daB1939B00b146894A);
  IPool public constant constant_product_pair = IPool(0x911a89dE0430A5cE3699E57D508f8678Afa1fffc); // ABAS-ETH (1%)
  IPool public constant stable_product_pair = IPool(0xB059CF6320B29780C39817c42aF1a032bf821D90); // USDC-USDT (0.01%)
  IERC20 public constant ETH  = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  IWETH public constant WETH  = IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  IERC20 public constant ABAS = IERC20(0x0B549125fbEA37E52Ee05FA388a3A0a7Df792Fa7);
  IERC20 public constant USDT = IERC20(0x94b008aA00579c1307B0EF2c499aD98a8ce58e58);

  constructor(){}
    
  // Example swapping between tokens on a constant-product pool
    function swapToETH(address payable _to, uint AmountOfABAS, uint minAmountOfETH) public {
        
            ABAS.transferFrom(msg.sender, address(this), AmountOfABAS);

            uint ABAS_Balance_is = ABAS.balanceOf(address(this));


            // Transfer the specified amount of ABAS to BentoBox
            ABAS.transfer(address(bentobox), ABAS_Balance_is);
        
            // Deposit the specified amount of ABAS into BentoBox
            bentobox.deposit(ABAS, address(bentobox), address(constant_product_pair), ABAS_Balance_is, 0);
        
            // Encode call data to make the swap
            bytes memory swapData = abi.encode(address(ABAS), address(this), true);
        
        
            // Execute the Swap
            uint amountOut = constant_product_pair.swap(swapData);
        
            // Check minOut to prevent slippage (example of using 0 for minOut has no slippage protection)
            require(amountOut >= minAmountOfETH, "You would not recieve enough tokens for this swap, try again slippage issue");
        
            // Call the withdraw function of the WETH contract
            WETH.withdraw(IERC20(ETH).balanceOf(address(this)));

            (bool sent, ) = _to.call{value: address(this).balance }("");
            require(sent, "Failed to send Ether");
    }

  
  // Example swapping between tokens on a constant-product pool
    function swapToABAS(address payable _to, uint AmountOfETH, uint minAmountOfABAS) public payable {
            require(AmountOfETH <= msg.value,"Amount of eth to swap must be same or less than msg.value");
            
            // Call the withdraw function of the WETH contract
            WETH.deposit(address(this).balance);
/*
            uint ABAS_Balance_is = ABAS.balanceOf(address(this));
            // Transfer the specified amount of ABAS to BentoBox
            ABAS.transfer(address(bentobox), ABAS_Balance_is);
        
            // Deposit the specified amount of ABAS into BentoBox
            bentobox.deposit(ABAS, address(bentobox), address(constant_product_pair), ABAS_Balance_is, 0);
        
            // Encode call data to make the swap
            bytes memory swapData = abi.encode(address(ABAS), address(this), true);
        
        */
          uint wethBalanceOnContract = IERC20(ETH).balanceOf(address(this));
          // Transfer the specified amount of WETH to BentoBox
            IERC20(ETH).transfer(address(bentobox), wethBalanceOnContract);
        
            // Deposit the specified amount of ABAS into BentoBox
            bentobox.deposit(ETH, address(bentobox), address(constant_product_pair), wethBalanceOnContract, 0);
        
            // Encode call data to make the swap
            bytes memory swapData = abi.encode(address(WETH), address(this), true);

            // Execute the Swap
            uint amountOut = constant_product_pair.swap(swapData);
        
            // Check minOut to prevent slippage (example of using 0 for minOut has no slippage protection)
            require(amountOut >= minAmountOfABAS, "You would not recieve enough tokens for this swap, try again slippage issue");
        
            // Call the transfer to the person intended
            ABAS.transfer(_to, ABAS.balanceOf(address(this)));

    }
	  //Allow ETH to enter
	receive() external payable {

	}


	fallback() external payable {

	}
}
