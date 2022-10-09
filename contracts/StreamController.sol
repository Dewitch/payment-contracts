// SPDX-License-Identifier: UNLICENSED
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
        uint256 numberOfStreams;
        address streamerAddress;
        bool isActive;
        bool isStreaming;
        int96 activeStreamFlowRate;
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

    address[] private _streamers;

    // hash(streamerAddress, streamId) -> array of watchers
    mapping(bytes32 => address[]) internal _currentStreamWatchers;

    // address of streamer -> struct of streamer info
    mapping(address => SteamerDetailsMapObject)
        internal _streamerAddressToDetails;

    // address of streamer -> array of all watchers ever
    mapping(address => address[]) internal _streamerAddressToAllWatchers;

    // hash(streamerAddress, watcherAddress) -> array of stream ids
    mapping(bytes32 => string[]) internal _streamerWatcherHistory;

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
    ) internal pure returns (bytes32) {
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
        _updateStreamToken(_newStreamTokenAddress);
    }

    /**
     * @notice [INTERNAL] Owner function to update the stream token reference
     * @param _newStreamTokenAddress Address of the new superfluid token
     */
    function _updateStreamToken(address _newStreamTokenAddress) internal {
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
        _updateSubscriptionHandler(_newSubscriptionHandlerAddress);
    }

    /**
     * @notice [INTERNAL] Owner function to update the subscription handler contract reference
     * @param _newSubscriptionHandlerAddress Address of the new subscription contract
     */
    function _updateSubscriptionHandler(address _newSubscriptionHandlerAddress)
        internal
    {
        address oldSubscriptionHandlerAddress = address(_subscriptionHandler);
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
        returns (address[] memory)
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
    function registerAsStreamer(string memory streamerName)
        external
        override
        whenNotPaused
    {
        _registerAsStreamer(streamerName);
    }

    /**
     * @notice [INTERNAL] The first function that streamers need to call to get started
     * @param streamerName String representation of what streamers want to be called
     */
    function _registerAsStreamer(string memory streamerName) internal {
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
        // activeStreamFlowRate defaults to 0
        // numberOfStreams defaults to 0

        // Add the current user as a streamer
        _streamers.push(_msgSender());

        emit RegisteredStreamer(_msgSender(), streamerName, streamerName);
    }

    /**
     * @notice The function to call to begin a stream, can only have one stream at a time
     * @param streamId String of the stream
     */
    function startStream(string memory streamId, int96 perSecondStreamRate)
        external
        override
        whenNotPaused
        onlyStreamer
        whenNotStreaming(_msgSender())
    {
        _startStream(streamId, perSecondStreamRate);
    }

    /**
     * @notice [INTERNAL] The function to call to begin a stream, can only have one stream at a time
     * @param streamId String of the stream
     */
    function _startStream(string memory streamId, int96 perSecondStreamRate)
        internal
    {
        // Update the storage struct streaming details
        SteamerDetailsMapObject
            storage specificStreamerMapObj = _streamerAddressToDetails[
                _msgSender()
            ];

        specificStreamerMapObj.isStreaming = true;
        specificStreamerMapObj.activeStreamId = streamId;
        specificStreamerMapObj.activeStreamFlowRate = perSecondStreamRate;
        specificStreamerMapObj.numberOfStreams =
            specificStreamerMapObj.numberOfStreams +
            1;

        emit StreamStarted(
            _msgSender(),
            specificStreamerMapObj.numberOfStreams,
            perSecondStreamRate
        );
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
        _endStream();
    }

    /**
     * @notice The function to call to end the active stream
     */
    function _endStream() internal {
        address[] memory currentStreamWatchers = _getMyActiveStreamWatchers();
        uint256 currentStreamWatcherCount = currentStreamWatchers.length;

        // Loop through all the current watchers and stop the stream
        for (uint256 i = 0; i < currentStreamWatcherCount; i++) {
            address currentStreamWatcher = currentStreamWatchers[i];

            _stopWatchingStreamer(_msgSender(), currentStreamWatcher);
        }

        // Update the storage struct streaming details
        SteamerDetailsMapObject
            storage specificStreamerMapObj = _streamerAddressToDetails[
                _msgSender()
            ];

        specificStreamerMapObj.isStreaming = false;
        specificStreamerMapObj.activeStreamId = "";
        specificStreamerMapObj.activeStreamFlowRate = 0;

        emit StreamEnded(_msgSender(), currentStreamWatcherCount);
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
     * @notice The function to call to get back the currently cost of the active stream
     */
    function getMyActiveStreamRate()
        external
        view
        override
        whenNotPaused
        onlyStreamer
        whenStreaming(_msgSender())
        returns (int96)
    {
        return _getStreamerDetails(_msgSender()).activeStreamFlowRate;
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

    // // // // // // // // // // // // // // // // // // // //
    // WATCHER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice The function to call as a watcher to start payment and get back the currently active stream
     * @param streamerAddress Address of the streamer to watch
     * @return streamId
     */
    function startWatchingStreamer(address streamerAddress)
        external
        override
        whenNotPaused
        whenStreaming(streamerAddress)
        returns (string memory)
    {
        return _startWatchingStreamer(streamerAddress, _msgSender());
    }

    /**
     * @notice [INTERNAL] The function to call as a watcher to start payment and get back the currently active stream
     * @param streamerAddress Address of the streamer to watch
     * @param watcherAddress Address of the watcher of the stream
     * @return streamId
     */
    function _startWatchingStreamer(
        address streamerAddress,
        address watcherAddress
    ) internal returns (string memory) {
        // The hash of the streamer with the watcher address as an index
        bytes32 streamerWatcherHash = _getStreamerWatcherHash(
            streamerAddress,
            watcherAddress
        );

        // Check that the user isnt currently paying to watch this streamer
        require(
            !_isWatcherPaying[streamerWatcherHash],
            "Already watching stream"
        );

        // Add the user to the list of watchers
        _currentStreamWatchers[_getActiveStreamHash(streamerAddress)].push(
            watcherAddress
        );

        // Get the total count of previous streams watched
        uint256 countOfPastStreams = _streamerWatcherHistory[
            streamerWatcherHash
        ].length;

        // If the count of the stream history is 0 then add them to the overall watchers list
        if (countOfPastStreams == 0) {
            // Add the current watcher to the list of all watchers ever
            _streamerAddressToAllWatchers[streamerAddress].push(watcherAddress);
        }

        // Add the current stream id to the watch history of this user with this streamer
        _streamerWatcherHistory[streamerWatcherHash].push(
            _getStreamerDetails(streamerAddress).activeStreamId
        );

        // Set the steam of payment
        _subscriptionHandler.createSubscriptionFlow(
            // address tokenAddress,
            _streamToken,
            // int96 flowRate,
            _getStreamerDetails(streamerAddress).activeStreamFlowRate,
            // address fromAddress,
            watcherAddress,
            // address toAddress
            streamerAddress
        );

        // Update that the watcher is paying
        _isWatcherPaying[streamerWatcherHash] = true;

        emit StartedWatchingStream(streamerAddress, watcherAddress);

        return _getStreamerDetails(streamerAddress).activeStreamId;
    }

    /**
     * @notice The function to call as a watcher to stop payment
     * @param streamerAddress Address of the streamer to watch
     */
    function stopWatchingStreamer(address streamerAddress)
        external
        override
        whenNotPaused
        whenStreaming(streamerAddress)
    {
        _stopWatchingStreamer(streamerAddress, _msgSender());
    }

    /**
     * @notice [INTERNAL] The function to call as a watcher to stop payment
     * @param streamerAddress Address of the streamer to stop watching
     * @param watcherAddress Address of the watcher of the stream
     */
    function _stopWatchingStreamer(
        address streamerAddress,
        address watcherAddress
    ) internal {
        // Delete current flow
        _subscriptionHandler.deleteSubscriptionFlow(
            // address tokenAddress,
            _streamToken,
            // address fromAddress,
            watcherAddress,
            // address toAddress
            streamerAddress
        );

        // Update that the watcher isnt paying
        _isWatcherPaying[
            _getStreamerWatcherHash(streamerAddress, watcherAddress)
        ] = false;

        emit StoppedWatchingStream(streamerAddress, watcherAddress);
    }

    /**
     * @notice The function to call as a watcher to get back the currently active stream
     * @param streamerAddress Address of the streamer to watch
     */
    function getWatcherStreamId(address streamerAddress)
        external
        view
        override
        whenNotPaused
        whenStreaming(streamerAddress)
        returns (string memory)
    {
        return _getWatcherStreamId(streamerAddress, _msgSender());
    }

    /**
     * @notice [INTERNAL] The function to call as a watcher to get back the currently active stream
     * @param streamerAddress Address of the streamer to watch
     * @param watcherAddress Address of the watcher of the stream
     */
    function _getWatcherStreamId(
        address streamerAddress,
        address watcherAddress
    ) internal view returns (string memory) {
        // The hash of the streamer with the watcher address as an index
        bytes32 streamerWatcherHash = _getStreamerWatcherHash(
            streamerAddress,
            watcherAddress
        );

        // Check that the user is currently paying to watch this streamer
        require(
            _isWatcherPaying[streamerWatcherHash],
            "Not paying for the stream"
        );

        return _getStreamerDetails(streamerAddress).activeStreamId;
    }
}
