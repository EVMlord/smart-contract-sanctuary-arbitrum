// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

/// @title  A global key value store
/// @notice Stores values against a key, combines msg.sender with the provided key to ensure uniqueness
contract KeyValueStore {
    mapping(uint256 => uint256) public store;

    /// @notice Sets a value in the store
    /// @dev    Combines the provided key with the msg.sender to ensure uniqueness
    function set(uint256 key, uint256 value) external {
        store[computeKey(msg.sender, key)] = value;
    }

    /// @notice Get a value from the store for the current msg.sender
    function get(uint256 key) external view returns (uint256) {
        return _get(msg.sender, key);
    }

    /// @notice Get a value from the store for any sender
    function get(address owner, uint256 key) external view returns (uint256) {
        return _get(owner, key);
    }

    /// @notice Compute the composite key for a specific user
    function computeKey(address owner, uint256 key) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(owner, key)));
    }

    function _get(address owner, uint256 key) internal view returns (uint256) {
        return store[computeKey(owner, key)];
    }
}