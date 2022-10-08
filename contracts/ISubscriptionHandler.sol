pragma solidity ^0.8.2;

import {ISuperfluid, ISuperToken, ISuperApp} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {ISuperfluidToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluidToken.sol";

interface ISubscriptionHandler {
    // // // // // // // // // // // // // // // // // // // //
    // EVENTS
    // // // // // // // // // // // // // // // // // // // //

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
