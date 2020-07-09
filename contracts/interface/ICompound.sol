
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.11;

interface IComptroller {
    function markets(address) external returns (bool, uint256);

    function enterMarkets(address[] calldata)
        external
        returns (uint256[] memory);

    function exitMarket(address) external returns (uint256);

    function getAccountLiquidity(address)
        external
        view
        returns (uint256, uint256, uint256);
}


interface IPriceOracle {
    function getUnderlyingPrice(address) external view returns (uint256);
}