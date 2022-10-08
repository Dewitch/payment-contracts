pragma solidity ^0.8.2;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Local interfaces
import "../interfaces/IStreamController.sol";
import "../interfaces/ISubscriptionHandler.sol";

contract StreamController is Ownable, Pausable, IStreamController {
    // // // // // // // // // // // // // // // // // // // //
    // LIBRARIES AND STRUCTS
    // // // // // // // // // // // // // // // // // // // //

    struct SteamerDetailsMapObject {
        address streamerAddress;
        uint256 numberOfStreams;
        bool isActive;
        bool isStreaming;
        string streamerName;
        string activeStreamId;
    }

    // // // // // // // // // // // // // // // // // // // //
    // VARIABLES
    // // // // // // // // // // // // // // // // // // // //

    // Contract to handle subscriptions
    ISubscriptionHandler private _subscriptionHandler;

    // The token address that will be streamed
    address private _streamToken;

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

    constructor(address _streamTokenAddress) {
        _streamToken = _streamTokenAddress;
    }

    // // // // // // // // // // // // // // // // // // // //
    // MODIFIERS
    // // // // // // // // // // // // // // // // // // // //

    modifier onlyStreamer() {
        require(
            _getStreamerDetails(_msgSender()).isActive,
            "Must be a streamer"
        );

        _;
    }

    modifier whenNotStreaming(address streamerAddress) {
        require(
            !_getStreamerDetails(streamerAddress).isStreaming,
            "Currently streaming"
        );

        _;
    }

    modifier whenStreaming(address streamerAddress) {
        require(
            _getStreamerDetails(streamerAddress).isStreaming,
            "Not streaming"
        );

        _;
    }

    // // // // // // // // // // // // // // // // // // // //
    // HELPER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice Returns the entire object for the given address
     */
    function _getStreamerDetails(address streamerAddress)
        internal
        view
        returns (SteamerDetailsMapObject memory)
    {
        return _streamerAddressToDetails[streamerAddress];
    }

    function _getActiveStreamHash(address streamerAddress)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    streamerAddress,
                    _getStreamerDetails(streamerAddress).activeStreamId
                )
            );
    }

    function _getStreamerWatcherHash(
        address streamerAddress,
        address watcherAddress
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(streamerAddress, watcherAddress));
    }

    // // // // // // // // // // // // // // // // // // // //
    // OWNER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice Pause this contract
     * @param val Pause state to set
     */
    function pause(bool val) external override onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    /**
     * @notice Owner function to update the stream token reference
     * @param _newStreamTokenAddress Address of the new superfluid token
     */
    function updateStreamToken(address _newStreamTokenAddress)
        external
        override
        onlyOwner
    {
        address oldStreamTokenAddress = _streamToken;
        _streamToken = _newStreamTokenAddress;

        emit UpdatedStreamToken(oldStreamTokenAddress, _newStreamTokenAddress);
    }

    /**
     * @notice Owner function to update the subscription handler contract reference
     * @param _newSubscriptionHandlerAddress Address of the new subscription contract
     */
    function updateSubscriptionHandler(address _newSubscriptionHandlerAddress)
        external
        override
        onlyOwner
    {
        address oldSubscriptionHandlerAddress = _subscriptionHandler;
        _subscriptionHandler = ISubscriptionHandler(
            _newSubscriptionHandlerAddress
        );

        emit UpdatedSubscriptionHandler(
            oldSubscriptionHandlerAddress,
            _newSubscriptionHandlerAddress
        );
    }

    // // // // // // // // // // // // // // // // // // // //
    // VIEW FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice View function to get the list streamers
     */
    function streamers()
        external
        view
        override
        whenNotPaused
        returns (string[] memory)
    {
        return _streamers;
    }

    // // // // // // // // // // // // // // // // // // // //
    // STREAMER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice The first function that streamers need to call to get started
     * @param streamerName String representation of what streamers want to be called
     */
    function registerAsStream(string memory streamerName)
        external
        override
        whenNotPaused
    {
        _registerAsStream(streamerName);
        emit RegisteredStreamer(_msgSender(), streamerName, streamerName);
    }

    /**
     * @notice [INTERNAL] The first function that streamers need to call to get started
     * @param streamerName String representation of what streamers want to be called
     */
    function _registerAsStream(string memory streamerName) internal {
        // Set up the storage struct
        SteamerDetailsMapObject
            storage specificStreamerMapObj = _streamerAddressToDetails[
                _msgSender()
            ];

        // Check for an already registered streamer
        require(
            !specificStreamerMapObj.isActive,
            "Streamer already registered"
        );

        // Set up the struct of the streamer details
        specificStreamerMapObj.streamerAddress = _msgSender();
        specificStreamerMapObj.streamerName = streamerName;
        specificStreamerMapObj.isActive = true;
        // isStreaming defaults to false
        // activeStreamId defaults to blank

        // Add the current user as a streamer
        _streamers.push(_msgSender());
    }

    /**
     * @notice The function to call to begin a stream, can only have one stream at a time
     * @param streamId String of the stream
     */
    function startStream(string memory streamId)
        external
        override
        whenNotPaused
        onlyStreamer
        whenNotStreaming(_msgSender())
    {
        _startStream(streamId);

        emit StreamStarted(
            _msgSender(),
            specificStreamerMapObj.numberOfStreams
        );
    }

    /**
     * @notice [INTERNAL] The function to call to begin a stream, can only have one stream at a time
     * @param streamId String of the stream
     */
    function _startStream(string memory streamId) internal {
        // Update the storage struct streaming details
        SteamerDetailsMapObject
            storage specificStreamerMapObj = _streamerAddressToDetails[
                _msgSender()
            ];

        specificStreamerMapObj.isStreaming = true;
        specificStreamerMapObj.activeStreamId = streamId;
        specificStreamerMapObj.numberOfStreams =
            specificStreamerMapObj.numberOfStreams +
            1;
    }

    /**
     * @notice The function to call to end the active stream
     */
    function endStream()
        external
        override
        whenNotPaused
        onlyStreamer
        whenStreaming(_msgSender())
    {
        address[] memory currentStreamWatchers = _getMyActiveStreamWatchers();
        uint256 currentStreamWatcherCount = currentStreamWatchers.length;

        _endStream();

        emit StreamEnded(_msgSender(), currentStreamWatcherCount);
    }

    /**
     * @notice The function to call to end the active stream
     */
    function _endStream() internal {
        address[] memory currentStreamWatchers = _getMyActiveStreamWatchers();

        // Loop through all the current watchers and stop the stream
        for (uint256 i = 0; i < currentStreamWatcherCount; i++) {
            address currentStreamWatcher = currentStreamWatchers[i];

            // Delete current flow
            _subscriptionHandler.deleteSubscriptionFlow(
                _streamToken,
                // address fromAddress,
                currentStreamWatcher,
                // address toAddress
                _msgSender()
            );

            // Update that the watcher isnt streaming
            _isWatcherPaying[
                _getStreamerWatcherHash(_msgSender(), currentStreamWatcher)
            ] = false;
        }

        // Update the storage struct streaming details
        SteamerDetailsMapObject
            storage specificStreamerMapObj = _streamerAddressToDetails[
                _msgSender()
            ];

        specificStreamerMapObj.isStreaming = false;
        specificStreamerMapObj.activeStreamId = "";
    }

    /**
     * @notice The function to call to get back the currently active stream
     */
    function getMyActiveStream()
        external
        view
        override
        whenNotPaused
        onlyStreamer
        whenStreaming(_msgSender())
        returns (string memory)
    {
        return _getStreamerDetails(_msgSender()).activeStreamId;
    }

    /**
     * @notice The function to call to get back all the watchers of the currently active stream
     */
    function getMyActiveStreamWatchers()
        external
        view
        override
        whenNotPaused
        onlyStreamer
        whenStreaming(_msgSender())
        returns (address[] memory)
    {
        return _getMyActiveStreamWatchers();
    }

    /**
     * @notice [INTERNAL] The function to call to get back all the watchers of the currently active stream
     */
    function _getMyActiveStreamWatchers()
        internal
        view
        returns (address[] memory)
    {
        return _currentStreamWatchers[_getActiveStreamHash(_msgSender())];
    }

    /**
     * @notice The function to call to get back all the watchers
     */
    function getMyWatchers()
        external
        view
        override
        whenNotPaused
        onlyStreamer
        whenStreaming(_msgSender())
        returns (address[] memory)
    {
        return _getMyWatchers();
    }

    /**
     * @notice [INTERNAL ] The function to call to get back all the watchers
     */
    function _getMyWatchers() internal view returns (address[] memory) {
        return _streamerAddressToAllWatchers[_msgSender()];
    }
}
