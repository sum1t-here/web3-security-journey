// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

contract CrossContract {
    /**
     * The function below is to call the price function of PriceOracle1 and PriceOracle2 contracts below and return the lower of the two prices
     */

    function getLowerPrice(
        address _priceOracle1,
        address _priceOracle2
    ) external view returns (uint256) {
        (bool success1, bytes memory data1) =
            _priceOracle1.staticcall(abi.encodeWithSignature("price()"));
        (bool success2, bytes memory data2) =
            _priceOracle2.staticcall(abi.encodeWithSignature("price()"));

        if (!success1 || !success2) {
            revert("Failed to call price function");
        }

        uint256 price1 = abi.decode(data1, (uint256));
        uint256 price2 = abi.decode(data2, (uint256));

        return price1 < price2 ? price1 : price2;
    }
}

contract PriceOracle1 {
    uint256 private _price;

    function setPrice(uint256 newPrice) public {
        _price = newPrice;
    }

    function price() external view returns (uint256) {
        return _price;
    }
}

contract PriceOracle2 {
    uint256 private _price;

    function setPrice(uint256 newPrice) public {
        _price = newPrice;
    }

    function price() external view returns (uint256) {
        return _price;
    }
}