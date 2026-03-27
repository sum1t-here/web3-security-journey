/*
* Verification of GasBadNftMarketplace
*/

using GasBadNftMarketplace as gasBadNftMarketplace;
using NftMarketplace as nftMarketplace;

methods {
    function getListing(address nftAddress, uint256 tokenId) external returns (INftMarketplace.Listing) envfree;
    function getProceeds(address seller) external returns uint256 envfree;
    // use nftMock.transferFrom for all safeTransferFrom calls
    function _.safeTransferFrom(address, address, uint256) external => DISPATCHER(true);
    function _.onERC721Received(address, address, uint256, bytes) external => DISPATCHER(true);
}

ghost mathint listingUpdatesCount {
    // initial state will be 0
    // axiom => require such to be true
    init_state axiom listingUpdatesCount == 0;
}
ghost mathint log4Count {
    init_state axiom log4Count == 0;
}

hook Sstore s_listings[KEY address nftAddress][KEY uint256 tokenId].price uint256 price {
    listingUpdatesCount = listingUpdatesCount + 1;
}

hook LOG4(uint offset, uint length, bytes32 t1, bytes32 t2, bytes32 t3, bytes32 t4) {
    log4Count = log4Count + 1;
}

// rules

invariant anytime_mapping_updated_emit_event()
    listingUpdatesCount <= log4Count;

rule calling_any_function_should_result_in_each_contract_having_the_same_state(method f, method g){
    require(f.selector == g.selector);
    env e;
    calldataarg args;
    address listingAddr;
    uint256 tokenId;
    address seller;

    require(gasBadNftMarketplace.getProceeds(e, seller) == nftMarketplace.getProceeds(e, seller));
    require(gasBadNftMarketplace.getListing(e, listingAddr, tokenId).price == nftMarketplace.getListing(e, listingAddr, tokenId).price);
    require(gasBadNftMarketplace.getListing(e, listingAddr, tokenId).seller == nftMarketplace.getListing(e, listingAddr, tokenId).seller);
    

    gasBadNftMarketplace.f(e, args);
    nftMarketplace.g(e, args);


    assert gasBadNftMarketplace == nftMarketplace;
    assert gasBadNftMarketplace.getProceeds(e, seller) == nftMarketplace.getProceeds(e,seller);
    assert gasBadNftMarketplace.getListing(e, listingAddr, tokenId).price == nftMarketplace.getListing(e, listingAddr, tokenId).price;
    assert gasBadNftMarketplace.getListing(e, listingAddr, tokenId).seller == nftMarketplace.getListing(e, listingAddr, tokenId).seller;
}