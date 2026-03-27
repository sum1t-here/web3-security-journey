/**
 * Verification of NftMock 
 **/

methods {
    // Non-summary declarations
    // Use the fn as defined in the codebase
    //// Sometimes the fn is too complex
    //// Sometimes the functions are only called by one or two contracts
    //// Sometimes we want to make more assumptions for the prover to run
    function totalSupply() external returns uint256 envfree;
    function mint() external;
    function balanceOf(address) external returns uint256 envfree;
}

invariant totalSupplyIsNotNegative()
    totalSupply() >= 0;

rule minting_mints_one_nft() {
    // Arrange
    env e;
    address minter;
    require e.msg.value == 0, "mint() is not payable, so msg.value must be 0";
    require e.msg.sender == minter;
    mathint balanceBefore = balanceOf(minter);
    
    // Act
    // currentContract refers to the contract file mentioned in src
    // if working with env pass e as parameter
    currentContract.mint(e);
    
    // Assert
    assert to_mathint(balanceOf(minter)) == balanceBefore + 1, "Only one nft is minted";
}

// rule sanity {
//     satisfy true;
// }

// Parametric rule
// wh f is any method in the contract
// rule no_change_to_total_supply(method f){
//     uint256 totalSupplyBefore = totalSupply();

//     env e;
//     calldataarg arg;
//     f(e, arg);

//     assert totalSupply() == totalSupplyBefore, "Total supply should not change";
// }