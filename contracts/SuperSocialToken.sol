// SPDX-License-Identifier: AGPLv3
pragma solidity ^0.8.0;

import {SuperTokenBase} from "./base/SuperTokenBase.sol";

/// @title Burnable and Mintable Pure Super Token
/// @notice This does not perform checks when burning
contract SuperSocialToken is SuperTokenBase {
    address private _socialTokenOwner;

    // // // // // // // // // // // // // // // // // // // //
    // CONSTRUCTOR
    // // // // // // // // // // // // // // // // // // // //

    constructor(address socialTokenOwnerAddress) {
        _socialTokenOwner = socialTokenOwnerAddress;
    }

    /// @notice Initializer, used AFTER factory upgrade
    /// @dev We MUST mint here, there is no other way to mint tokens
    /// @param factory Super Token factory for initialization
    /// @param name Name of Super Token
    /// @param symbol Symbol of Super Token
    /// @param initialSupply Initial token supply to pre-mint
    /// @param receiver Receiver of pre-mint
    function initialize(
        address factory,
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address receiver
    ) external {
        _initialize(factory, name, symbol);
        _mint(receiver, initialSupply, new bytes(0));
    }

    // // // // // // // // // // // // // // // // // // // //
    // MODIFIERS
    // // // // // // // // // // // // // // // // // // // //

    modifier onlySocialTokenOwner() {
        require(
            _socialTokenOwner == msg.sender,
            "Must be a social token owner"
        );

        _;
    }

    /// @notice Mints tokens, only the owner may do this
    /// @param receiver Receiver of minted tokens
    /// @param amount Amount to mint
    function mint(address receiver, uint256 amount)
        external
        onlySocialTokenOwner
    {
        _mint(receiver, amount, new bytes(0));
    }

    /// @notice Burns from message sender
    /// @param amount Amount to burn
    function burn(uint256 amount) external {
        _burn(msg.sender, amount, new bytes(0));
    }
}
