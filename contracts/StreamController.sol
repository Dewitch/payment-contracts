pragma solidity ^0.8.2;

// Local interfaces
import "../interfaces/IStreamController.sol";
import "../interfaces/ISubscriptionHandler.sol";

error Unauthorized();

contract StreamController is IStreamController {
    // // // // // // // // // // // // // // // // // // // //
    // LIBRARIES AND STRUCTS
    // // // // // // // // // // // // // // // // // // // //

    struct SteamerDetailsMapObject {
        address streamerAddress;
        bool isActive;
        string streamerName;
        string activeStreamId;
    }

    // // // // // // // // // // // // // // // // // // // //
    // VARIABLES
    // // // // // // // // // // // // // // // // // // // //

    address private _owner;

    // Contract to
    ISubscriptionHandler private _subscriptionHandler;

    string[] private _streamers;

    // hash(streamerAddress, streamId) -> array of watchers
    mapping(bytes32 => address[]) internal _currentStreamWatchers;

    // address of streamer -> struct of streamer info
    mapping(address => SteamerDetailsMapObject)
        internal _streamerAddressToDetails;

    // address of streamer -> array of all watchers ever
    mapping(address => address[]) internal _streamerAddressToAllWatchers;

    // hash(streamerAddress, watcherAddress) -> array of stream ids
    mapping(bytes32 => address[]) internal _streamerWatcherHistory;

    // hash(streamerAddress, watcherAddress) -> boolean if the payment is currenly active
    mapping(bytes32 => bool) internal _isWatcherPaying;

    // // // // // // // // // // // // // // // // // // // //
    // CONSTRUCTOR
    // // // // // // // // // // // // // // // // // // // //

    constructor(address _newOwner, address _newSubscriptionHandler) {
        _owner = _newOwner;
    }

    // // // // // // // // // // // // // // // // // // // //
    // MODIFIERS
    // // // // // // // // // // // // // // // // // // // //

    modifier onlyOwner(address msgSender) {
        if (msgSender != _owner) revert Unauthorized();
        _;
    }

    // // // // // // // // // // // // // // // // // // // //
    // OWNER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice Owner function to update the subscription handler contract reference
     * @param _newSubscriptionHandlerAddress Address of the new subscription contract
     */
    function setSubscriptionHandler(address _newSubscriptionHandlerAddress)
        external
        onlyOwner(msg.sender)
    {
        _subscriptionHandler = ISubscriptionHandler(_newSubscriptionHandler);
    }

    // // // // // // // // // // // // // // // // // // // //
    // VIEW FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice View function to get the list streamers
     */
    function streamers() external view returns (string[] memory) {
        return _streamers;
    }
}
