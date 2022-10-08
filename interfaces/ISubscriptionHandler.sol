pragma solidity ^0.8.2;

import {ISuperfluid, ISuperToken, ISuperApp} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {ISuperfluidToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluidToken.sol";

interface ISubscriptionHandler {
    // // // // // // // // // // // // // // // // // // // //
    // EVENTS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice Emitted when the controller address has been changed
     * @param owner The owner address that made this change
     * @param oldController The old controller address
     * @param newController The new controller address
     */
    event ChangedController(
        address indexed owner,
        address indexed oldController,
        address indexed newController
    );

    /**
     * @notice Emitted when the owner address has been changed
     * @param owner The owner address that made this change
     * @param oldOwner The old owner address
     * @param newOwner The new owner address
     */
    event ChangedOwner(
        address indexed owner,
        address indexed oldOwner,
        address indexed newOwner
    );

    /**
     * @notice Increase in the authorized flow rate of this contract for a given user
     * @param user The user that wants to allow the contract to stream
     * @param handler The contract that is allowed stream payment
     * @param token The token to allow streaming
     */
    event AuthorizedFullFlow(
        address indexed user,
        address indexed handler,
        address indexed token
    );

    /**
     * @notice Emitted when a subscription has been created
     * @param operator Controller or owner address that made the update
     * @param fromAddress The address that the stream is coming from
     * @param toAddress The address that the stream is going to
     * @param token The token to start streaming
     */
    event CreatedSubscriptionFlow(
        address operator,
        address indexed fromAddress,
        address indexed toAddress,
        address indexed token,
        int96 flowRate
    );

    /**
     * @notice Emitted when a subscription has been deleted
     * @param operator Controller or owner ddress that made the update
     * @param fromAddress The address that the stream is coming from
     * @param toAddress The address that the stream is going to
     * @param token The token to stop streaming
     */
    event DeletedSubscriptionFlow(
        address operator,
        address indexed fromAddress,
        address indexed toAddress,
        address indexed token
    );

    // // // // // // // // // // // // // // // // // // // //
    // VIEW FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice View controller function.
     */
    function controller() external view returns (address);

    /**
     * @notice View owner function.
     */
    function owner() external view returns (address);

    // // // // // // // // // // // // // // // // // // // //
    // OWNER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice Transfer controller address.
     * @param _newController New controller account.
     */
    function changeController(address _newController) external;

    /**
     * @notice Transfer ownership.
     * @param _newOwner New owner account.
     */
    function changeOwner(address _newOwner) external;

    // // // // // // // // // // // // // // // // // // // //
    // CONTROLLER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @dev Allow the user to let the contract create inifinite streams of value on their behalf
     * @param token Super token address
     */
    function authorizeFullFlow(ISuperfluidToken token) external;

    // // // // // // // // // // // // // // // // // // // //
    // BASE FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice Create a flow to the streamer.
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
    ) external;

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
    ) external;
}