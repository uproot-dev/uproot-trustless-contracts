// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.11;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


library MyUtils {
    function readBytes4(bytes memory b, uint256 index)
        internal
        pure
        returns (bytes4 result)
    {
        index += 32;
        assembly {
            result := mload(add(b, index))
            result := and(
                result,
                0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            )
        }
        return result;
    }

    function _toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function searchInsideArray(address search, address[] memory array)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == search) return true;
        }
        return false;
    }
}


interface CERC20 {
    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256)
        external
        returns (bool);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address)
        external
        view
        returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function getCash() external returns (uint256);

    function balanceOfUnderlying(address) external view returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function repayBorrowBehalf(address, uint256) external returns (uint256);

    function borrowBalanceCurrent(address) external view returns (uint256);
}
