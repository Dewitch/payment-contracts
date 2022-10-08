pragma solidity ^0.8.2;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ISuperfluid, ISuperToken, ISuperApp} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {ISuperfluidToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluidToken.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";

// Local interfaces
import "./ISubscriptionHandler.sol";

error Unauthorized();

contract SubscriptionHandler is ISubscriptionHandler {
    // ---------------------------------------------------------------------------------------------
    // STATE VARIABLES

    /// @notice Owner.
    address private _owner;

    /// @notice Owner.
    address private _controller;

    /// @notice CFA Library.
    using CFAv1Library for CFAv1Library.InitData;
    CFAv1Library.InitData public cfaV1;

    constructor(ISuperfluid host, address _newOwner) {
        assert(address(host) != address(0));
        _owner = _newOwner;

        // Initialize CFA Library
        cfaV1 = CFAv1Library.InitData(
            host,
            IConstantFlowAgreementV1(
                address(
                    host.getAgreementClass(
                        keccak256(
                            "org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
                        )
                    )
                )
            )
        );
    }

    // // // // // // // // // // // // // // // // // // // //
    // MODIFIERS
    // // // // // // // // // // // // // // // // // // // //

    modifier onlyController(address msgSender) {
        if (msgSender != _controller) revert Unauthorized();
        _;
    }

    modifier onlyControllerOrOwner(address msgSender) {
        if (msgSender != _controller && msgSender != _owner)
            revert Unauthorized();
        _;
    }

    modifier onlyOwner(address msgSender) {
        if (msgSender != _owner) revert Unauthorized();
        _;
    }

    // // // // // // // // // // // // // // // // // // // //
    // VIEW FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice View controller function.
     */
    function controller() external view override returns (address) {
        return _controller;
    }

    /**
     * @notice View owner function.
     */
    function owner() external view override returns (address) {
        return _owner;
    }

    // // // // // // // // // // // // // // // // // // // //
    // OWNER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice Transfer controller address.
     * @param _newController New controller account.
     */
    function changeController(address _newController)
        external
        override
        onlyOwner(msg.sender)
    {
        _controller = _newController;
    }

    /**
     * @notice Transfer ownership.
     * @param _newOwner New owner account.
     */
    function changeOwner(address _newOwner)
        external
        override
        onlyOwner(msg.sender)
    {
        _owner = _newOwner;
    }

    // // // // // // // // // // // // // // // // // // // //
    // CONTROLLER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @dev Allow the user to let the contract create inifinite streams of value on their behalf
     * @param token Super token address
     */
    function authorizeFullFlow(ISuperfluidToken token)
        external
        override
        onlyController(msg.sender)
    {
        cfaV1.authorizeFlowOperatorWithFullControl(
            token,
            address(this),
            new bytes(0)
        );
    }

    // // // // // // // // // // // // // // // // // // // //
    // BASE FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice Create a stream into the streamer.
     * @dev This requires the caller to be the controller contract
     * @param token Token to stream.
     * @param flowRate Flow rate per second to stream.
     * @param fromAddress The sending address of the stream.
     * @param toAddress The receiving address of the stream.
     */
    function createSubscriptionFlow(
        ISuperfluidToken token,
        int96 flowRate,
        address fromAddress,
        address toAddress
    ) external override onlyControllerOrOwner(msg.sender) {
        cfaV1.createFlowByOperator(fromAddress, toAddress, token, flowRate);
    }

    /**
     * @notice Delete a stream that the sender is sending
     * @param token Token to quit streaming.
     * @param fromAddress The sending address of the stream.
     * @param toAddress The receiving address of the stream.
     */
    function deleteSubscriptionFlow(
        ISuperfluidToken token,
        address fromAddress,
        address toAddress
    ) external override onlyControllerOrOwner(msg.sender) {
        cfaV1.deleteFlow(fromAddress, toAddress, token);
    }
}
