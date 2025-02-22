// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IntegrationDataTrackerStorage, Integration } from './IntegrationDataTrackerStorage.sol';

// This contract is a general store for when we need to store data that is relevant to an integration
// For example with GMX we must track what positions are open for each vault

contract IntegrationDataTracker {
    /**
     * @notice record new raw data
     * @param _integration used as the namespace for the data
     * @param _data the data track data to be recorded in storage
     */
    function pushData(Integration _integration, bytes memory _data) external {
        _pushData(_integration, msg.sender, _data);
    }

    /**
     * @notice delete data
     * @param _integration used as the namespace for the data
     * @param _index data index to be removed from storage
     */
    function removeData(Integration _integration, uint256 _index) external {
        _removeData(_integration, msg.sender, _index);
    }

    /**
     * @notice returns tracked data by index
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _index the index of data track data
     * @return data the data track data of given NFT_TYPE & poolLogic & index
     */
    function getData(
        Integration _integration,
        address _vault,
        uint256 _index
    ) external view returns (bytes memory) {
        return
            IntegrationDataTrackerStorage.layout().trackedData[_integration][
                _vault
            ][_index];
    }

    /**
     * @notice returns all tracked datas by NFT_TYPE & poolLogic
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @return data all tracked datas of given NFT_TYPE & poolLogic
     */
    function getAllData(
        Integration _integration,
        address _vault
    ) public view returns (bytes[] memory) {
        return
            IntegrationDataTrackerStorage.layout().trackedData[_integration][
                _vault
            ];
    }

    /**
     * @notice returns all tracked datas by NFT_TYPE & poolLogic
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @return count all tracked datas count of given NFT_TYPE & poolLogic
     */
    function getDataCount(
        Integration _integration,
        address _vault
    ) public view returns (uint256) {
        return
            IntegrationDataTrackerStorage
            .layout()
            .trackedData[_integration][_vault].length;
    }

    /**
     * @notice record new raw data
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _data the data track data to be recorded in storage
     */
    function _pushData(
        Integration _integration,
        address _vault,
        bytes memory _data
    ) private {
        IntegrationDataTrackerStorage
        .layout()
        .trackedData[_integration][_vault].push(_data);
    }

    /**
     * @notice delete data
     * @param _integration used as the namespace for the data
     * @param _vault the vaultAddress
     * @param _index data index to be removed from storage
     */
    function _removeData(
        Integration _integration,
        address _vault,
        uint256 _index
    ) private {
        IntegrationDataTrackerStorage.Layout
            storage l = IntegrationDataTrackerStorage.layout();
        uint256 length = l.trackedData[_integration][_vault].length;
        require(_index < length, 'invalid index');

        l.trackedData[_integration][_vault][_index] = l.trackedData[
            _integration
        ][_vault][length - 1];
        l.trackedData[_integration][_vault].pop();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// Not sure if we should use an enum here because the integrations are not fixed
// We could use a keccak("IntegrationName") instead, this contract will have to be upgraded if we add a new integration
// Because solidity validates enum params at runtime
enum Integration {
    GMXRequests,
    GMXPositions
}

library IntegrationDataTrackerStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.IntegationDataTracker');

    // solhint-disable-next-line ordering
    struct Layout {
        // used as the namespace for the data -> poolAddress -> data[]
        mapping(Integration => mapping(address => bytes[])) trackedData;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}