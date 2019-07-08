pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Capped.sol";
import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "./ERC20Metadata.sol";
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract ERC20CappedMetadata is ERC20Capped, ERC20Detailed, ERC20Metadata {
    using SafeMath for uint256;

    constructor(
      string memory name,
      string memory symbol,
      uint8 decimals,
      string memory uri,
      uint256 cap
    )
    ERC20Capped(cap)
    ERC20Detailed(name, symbol, decimals)
    ERC20Metadata(uri)
    { }
}