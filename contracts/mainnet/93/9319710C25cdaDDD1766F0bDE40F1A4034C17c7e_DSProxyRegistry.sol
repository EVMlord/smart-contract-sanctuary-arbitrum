// SPDX-License-Identifier: GNU-3
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

interface DSAuthority {
  function canCall(address src, address dst, bytes4 sig) external view returns (bool);
}

contract DSAuthEvents {
  event LogSetAuthority(address indexed authority);
  event LogSetOwner(address indexed owner);
}

contract DSAuth is DSAuthEvents {
  DSAuthority public authority;
  address public owner;

  constructor() public {
    owner = msg.sender;
    emit LogSetOwner(msg.sender);
  }

  function setOwner(address owner_) public auth {
    owner = owner_;
    emit LogSetOwner(owner);
  }

  function setAuthority(DSAuthority authority_) public auth {
    authority = authority_;
    emit LogSetAuthority(address(authority));
  }

  modifier auth() {
    require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
    _;
  }

  function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
    if (src == address(this)) {
      return true;
    } else if (src == owner) {
      return true;
    } else if (authority == DSAuthority(address(0))) {
      return false;
    } else {
      return authority.canCall(src, address(this), sig);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

contract DSNote {
  event LogNote(
    bytes4 indexed sig,
    address indexed guy,
    bytes32 indexed foo,
    bytes32 indexed bar,
    uint256 wad,
    bytes fax
  ) anonymous;

  modifier note() {
    bytes32 foo;
    bytes32 bar;

    assembly {
      foo := calldataload(4)
      bar := calldataload(36)
    }

    emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.6.0;

import { DSAuth } from "./DSAuth.sol";
import { DSNote } from "./DSNote.sol";

contract DSProxy is DSAuth, DSNote {
  DSProxyCache public cache; // global cache for dma-contracts

  constructor(address _cacheAddr) public {
    setCache(_cacheAddr);
  }

  function() external payable {}

  // use the proxy to execute calldata _data on contract _code
  function execute(
    bytes memory _code,
    bytes memory _data
  ) public payable returns (address target, bytes memory response) {
    target = cache.read(_code);
    if (target == address(0)) {
      // deploy contract & store its address in cache
      target = cache.write(_code);
    }

    response = execute(target, _data);
  }

  function execute(
    address _target,
    bytes memory _data
  ) public payable auth note returns (bytes memory response) {
    require(_target != address(0), "ds-proxy-target-address-required");

    // call contract in current context
    assembly {
      let succeeded := delegatecall(sub(gas, 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
      let size := returndatasize

      response := mload(0x40)
      mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
      mstore(response, size)
      returndatacopy(add(response, 0x20), 0, size)

      switch iszero(succeeded)
      case 1 {
        // throw if delegatecall failed
        revert(add(response, 0x20), size)
      }
    }
  }

  //set new cache
  function setCache(address _cacheAddr) public payable auth note returns (bool) {
    require(_cacheAddr != address(0), "ds-proxy-cache-address-required");
    cache = DSProxyCache(_cacheAddr); // overwrite cache
    return true;
  }
}

contract DSProxyFactory {
  event Created(address indexed sender, address indexed owner, address proxy, address cache);
  mapping(address => bool) public isProxy;
  DSProxyCache public cache;

  constructor() public {
    cache = new DSProxyCache();
  }

  // deploys a new proxy instance
  // sets owner of proxy to caller
  function build() public returns (address payable proxy) {
    proxy = build(msg.sender);
  }

  // deploys a new proxy instance
  // sets custom owner of proxy
  function build(address owner) public returns (address payable proxy) {
    proxy = address(new DSProxy(address(cache)));
    emit Created(msg.sender, owner, address(proxy), address(cache));
    DSProxy(proxy).setOwner(owner);
    isProxy[proxy] = true;
  }
}

contract DSProxyCache {
  mapping(bytes32 => address) cache;

  function read(bytes memory _code) public view returns (address) {
    bytes32 hash = keccak256(_code);
    return cache[hash];
  }

  function write(bytes memory _code) public returns (address target) {
    assembly {
      target := create(0, add(_code, 0x20), mload(_code))
      switch iszero(extcodesize(target))
      case 1 {
        // throw if contract failed to deploy
        revert(0, 0)
      }
    }
    bytes32 hash = keccak256(_code);
    cache[hash] = target;
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.0;

import {DSProxy, DSProxyFactory} from './DSProxy.sol';

// This Registry deploys new proxy instances through DSProxyFactory.build(address) and keeps a registry of owner => proxy
contract DSProxyRegistry {
  mapping(address => DSProxy) public proxies;
  DSProxyFactory factory;

  constructor(address factory_) public {
    factory = DSProxyFactory(factory_);
  }

  // deploys a new proxy instance
  // sets owner of proxy to caller
  function build() public returns (address payable proxy) {
    proxy = build(msg.sender);
  }

  // deploys a new proxy instance
  // sets custom owner of proxy
  function build(address owner) public returns (address payable proxy) {
    require(proxies[owner] == DSProxy(0) || proxies[owner].owner() != owner); // Not allow new proxy if the user already has one and remains being the owner
    proxy = factory.build(owner);
    proxies[owner] = DSProxy(proxy);
  }
}