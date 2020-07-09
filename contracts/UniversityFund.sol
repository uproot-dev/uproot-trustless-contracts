
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.11;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/Aave/aToken.sol";
import "./interface/Aave/ILendingPool.sol";
import "./interface/Aave/ILendingPoolAddressesProvider.sol";
import "./interface/IUniversityFund.sol";
import "./interface/ICompound.sol";
import "./MyUtils.sol";

contract UniversityFund is Ownable, AccessControl, IUniversityFund {
    using SafeMath for uint256;

    // FUNDS_MANAGER_ROLE can withdraw funds from the contract
    bytes32 public constant FUNDS_MANAGER_ROLE = keccak256(
        "FUNDS_MANAGER_ROLE"
    );

    //Compound Config
    CERC20 public cDAI;
    IComptroller public comptroller;
    IPriceOracle public priceOracle;

    //Aave Config
    ILendingPoolAddressesProvider _aaveProvider;
    ILendingPool _aaveLendingPool;
    address _aaveLendingPoolCore;
    address _aTokenDAI;

    //Tokens
    IERC20 public daiToken;

    /// @param daiAddress Adress of contract in the network
    constructor(
        address university,
        address daiAddress,
        address compoundDAIAddress,
        address comptrollerAddress,
        address priceOracleAddress,
        address lendingPoolAddressesProvider
    ) public {
        transferOwnership(university);
        daiToken = IERC20(daiAddress);
        IERC20(daiToken).approve(university, 2 ** 255);
        _setupRole(DEFAULT_ADMIN_ROLE, university);
        cDAI = CERC20(compoundDAIAddress);
        comptroller = IComptroller(comptrollerAddress);
        priceOracle = IPriceOracle(priceOracleAddress);
        _aaveProvider = ILendingPoolAddressesProvider(lendingPoolAddressesProvider);
        _aaveLendingPool = ILendingPool(_aaveProvider.getLendingPool());
        _aaveLendingPoolCore = _aaveProvider.getLendingPoolCore();
        _aTokenDAI = ILendingPoolCore(_aaveLendingPoolCore)
            .getReserveATokenAddress(address(daiToken));
    }

    /// @notice Allow receiving ETH
    receive() external payable {

    }

    /// @notice Allow taking ETH from the contract
    function withdraw(uint256 val) public override onlyOwner {
        TransferHelper.safeTransferETH(owner(), val);
    }

    /// @notice Allow view Owner
    /// @return address of Owner
    function ownerFund() public view override returns(address) {
        return owner();
    }

    /// @notice Grants role to account inside University Fund
    function grantRoleFund(bytes32 role, address account) public override {
        grantRole(role, account);
    }

    /// @notice Revoke role from account inside University Fund
    function revokeRoleFund(bytes32 role, address account) public override {
        revokeRole(role, account);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function applyFundsCompound(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        TransferHelper.safeApprove(address(daiToken), address(cDAI), val);
        cDAI.mint(val);
    }

    /// @notice Get the ammount of DAI applied in Compound
    /// @return ammount of DAI applied in Compound
    function appliedDAICompound() public view override returns (uint256) {
        return cDAI.balanceOfUnderlying(address(this));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function recoverFundsCompound(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        cDAI.redeemUnderlying(val);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function applyFundsAave(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        TransferHelper.safeApprove(address(daiToken), _aaveLendingPoolCore, val);
        _aaveLendingPool.deposit(address(daiToken), val, 0);
    }

    /// @notice Get the ammount of DAI applied in Aave
    /// @return ammount of DAI applied in Aave
    function appliedDAIAave() public view override returns (uint256) {
        return aToken(_aTokenDAI).balanceOf(address(this));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function recoverFundsAave(uint256 val) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        aToken(_aTokenDAI).redeem(val);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function setAaveMarketCollateralForDAI(bool state) public override {
        setAaveMarketCollateral(address(daiToken), state);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function setAaveMarketCollateral(address token, bool state) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        _aaveLendingPool.setUserUseReserveAsCollateral(token, state);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function enterCompoundDAIMarket() public override {
        enterCompoundMarket(address(cDAI));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function enterCompoundMarket(address token) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        address[] memory cTokens = new address[](1);
        cTokens[0] = token;
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        if (errors[0] != 0) {
            revert("University: Comptroller.enterMarkets failed.");
        }
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function exitCompoundDAIMarket() public override {
        exitCompoundMarket(address(cDAI));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function exitCompoundMarket(address token) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        uint256 error = comptroller.exitMarket(token);
        if (error != 0) {
            revert("University: Comptroller.exitMarket failed.");
        }
    }

    /// @notice Get the liquidity state in Compound
    /// @return liquidity and/or shortfall in ETH, expressed in WEI
    function getCompoundLiquidityAndShortfall() 
        public 
        view 
        override
        returns (uint256, uint256) {
        (uint256 error, uint256 liquidity, uint256 shortfall) = 
            comptroller
            .getAccountLiquidity(address(this));
        if (error != 0) {
            revert("University: Comptroller.getAccountLiquidity failed.");
        }
        return (liquidity, shortfall);
    }

    /// @notice Get the price from a specific token in Compound
    /// @param cToken Compound token address to query
    /// @return price in ETH, expressed in WEI
    function getCompoundPriceInWEI(address cToken) 
        public 
        view 
        override
        returns (uint256) {
        return priceOracle.getUnderlyingPrice(cToken);
    }

    /// @notice Get the maximum volume of tokens to borrow in Compound
    /// @param cToken Compound token address to query
    /// @return maximum borrow volume, expressed in WEI
    /// @dev Borrowing the maximum amount may lead to intant liquidation. Always borrow less than the maximum
    function getCompoundMaxBorrowInWEI(address cToken) 
        public 
        view 
        override
        returns (uint256) {
        (uint256 liquidity, ) = getCompoundLiquidityAndShortfall();
        return liquidity.div(priceOracle.getUnderlyingPrice(cToken));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function compoundBorrow(address cToken, uint256 val) 
        public 
        override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        CERC20(cToken).borrow(val);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function compoundGetBorrow(address cToken) 
        public 
        view 
        override
        returns (uint256) {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        return CERC20(cToken).borrowBalanceCurrent(address(this));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function compoundRepayBorrow(address token, address cToken, uint256 val)
        public 
        override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            IERC20(token).balanceOf(address(this)) >= val,
            "University: not enough of this token stored"
        );
        TransferHelper.safeApprove(token, cToken, val);
        CERC20(cToken).repayBorrow(val);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function aaveGetBorrow(address token, uint256 val, bool variableRate) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        uint8 vRate = variableRate ? 2 : 1;
        _aaveLendingPool.borrow(token, val, vRate, 0);
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function aaveRepayBorrow(address token, uint256 val)
        public 
        override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        require(
            IERC20(token).balanceOf(address(this)) >= val,
            "University: not enough of this token stored"
        );
        TransferHelper.safeApprove(token, _aaveProvider.getLendingPoolCore(), val);
        _aaveLendingPool.repay(token, val, address(this));
    }

    /// @notice Allow managing the university Funds. Must be called from an appointed Funds Manager
    function aaveSwapBorrowRateMode(address token) public override {
        require(
            hasRole(FUNDS_MANAGER_ROLE, _msgSender()),
            "University: caller doesn't have FUNDS_MANAGER_ROLE"
        );
        _aaveLendingPool.swapBorrowRateMode(token);
    }
}
