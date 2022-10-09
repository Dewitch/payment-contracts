// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IStreamController {
    // // // // // // // // // // // // // // // // // // // //
    // EVENTS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice Emitted when owner updates the stream token
     * @param oldStreamToken Address of the old stream token
     * @param newStreamToken Address of the new stream token
     */
    event UpdatedStreamToken(
        address indexed oldStreamToken,
        address indexed newStreamToken
    );

    /**
     * @notice Emitted when owner updates the super token factory
     * @param oldSuperTokenFactory Address of the old super token factory
     * @param newSuperTokenFactory Address of the new super token factory
     */
    event UpdatedSuperTokenFactory(
        address indexed oldSuperTokenFactory,
        address indexed newSuperTokenFactory
    );

    /**
     * @notice Emitted when owner updates the subscription handler
     * @param oldSubscriptionHandler Address of the old subscription handler
     * @param newSubscriptionHandler Address of the new subscription handler
     */
    event UpdatedSubscriptionHandler(
        address indexed oldSubscriptionHandler,
        address indexed newSubscriptionHandler
    );

    /**
     * @notice Emitted when a streamer is registered
     * @param streamerAddress Address of the streamer
     * @param streamerNameHash Indexed streamer name
     * @param streamerName The string representation of the streamer name
     */
    event RegisteredStreamer(
        address indexed streamerAddress,
        address indexed streamerSocialTokenAddress,
        string indexed streamerNameHash,
        string streamerName
    );

    /**
     * @notice Emitted when a streamer has started a stream
     * @param streamerAddress Address of the streamer
     * @param numberOfStreams Total count of streams
     * @param perSecondStreamRate Cost per second for this stream
     */
    event StreamStarted(
        address indexed streamerAddress,
        uint256 indexed numberOfStreams,
        int96 indexed perSecondStreamRate
    );

    /**
     * @notice Emitted when a streamer has ended a stream
     * @param streamerAddress Address of the streamer
     * @param numberOfWatchers Total count of watchers on the stream
     */
    event StreamEnded(
        address indexed streamerAddress,
        uint256 indexed numberOfWatchers
    );

    /**
     * @notice Emitted when a watcher has started watching a stream
     * @param streamerAddress Address of the streamer
     * @param watcherAddress Address of the watcher
     */
    event StartedWatchingStream(
        address indexed streamerAddress,
        address indexed watcherAddress
    );

    /**
     * @notice Emitted when a watcher has stopped watching a stream
     * @param streamerAddress Address of the streamer
     * @param watcherAddress Address of the watcher
     */
    event StoppedWatchingStream(
        address indexed streamerAddress,
        address indexed watcherAddress
    );

    // // // // // // // // // // // // // // // // // // // //
    // OWNER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice Pause this contract
     * @param val Pause state to set
     */
    function pause(bool val) external;

    /**
     * @notice Owner function to update the stream token reference
     * @param _newStreamTokenAddress Address of the new superfluid token
     */
    function updateStreamToken(address _newStreamTokenAddress) external;

    /**
     * @notice Owner function to update the super token factory
     * @param _newSuperTokenFactory Address of the super token factory
     */
    function updateSuperTokenFactory(address _newSuperTokenFactory) external;

    /**
     * @notice Owner function to update the subscription handler contract reference
     * @param _newSubscriptionHandlerAddress Address of the new subscription contract
     */
    function updateSubscriptionHandler(address _newSubscriptionHandlerAddress)
        external;

    // // // // // // // // // // // // // // // // // // // //
    // VIEW FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice View function to get the list streamers
     */
    function streamers() external view returns (address[] memory);

    /**
     * @notice View function to get the stream payment token
     */
    function streamToken() external view returns (address);

    /**
     * @notice View function to get the super token factory
     */
    function superTokenFactory() external view returns (address);

    /**
     * @notice View function to get the subsctription handler
     */
    function subscriptionHandler() external view returns (address);

    // // // // // // // // // // // // // // // // // // // //
    // STREAMER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice The first function that streamers need to call to get started
     * @param streamerName String representation of what streamers want to be called
     * @param socialTokenName Social token name
     * @param socialTokenSymbol Social token symbol
     */
    function registerAsStreamer(
        string memory streamerName,
        string memory socialTokenName,
        string memory socialTokenSymbol
    ) external;

    /**
     * @notice The function to call to begin a stream, can only have one stream at a time
     * @param streamName Name of the stream
     * @param streamId String of the stream
     * @param perSecondStreamRate cost of the stream
     */
    function startStream(
        string memory streamName,
        string memory streamId,
        int96 perSecondStreamRate
    ) external;

    /**
     * @notice The function to call to end the active stream
     */
    function endStream() external;

    /**
     * @notice The function to call to get back the currently active stream
     */
    function getMyActiveStream() external view returns (string memory);

    /**
     * @notice The function to call to get back the name of the currently active stream
     */
    function getMyActiveStreamName() external view returns (string memory);

    /**
     * @notice The function to call to get back the currently cost of the active stream
     */
    function getMyActiveStreamRate() external view returns (int96);

    /**
     * @notice The function to call to get back all the watchers of the currently active stream
     */
    function getMyActiveStreamWatchers()
        external
        view
        returns (address[] memory);

    /**
     * @notice The function to call to get back all the watchers
     */
    function getMyWatchers() external view returns (address[] memory);

    /**
     * @notice The function to get the streamer's token
     * @param streamerAddress Address of the streamer to watch
     */
    function getStreamerSocialToken(address streamerAddress)
        external
        view
        returns (address);

    /**
     * @notice The function to get if the steamer is active
     * @param streamerAddress Address of the streamer to watch
     */
    function getStreamerIsActive(address streamerAddress)
        external
        view
        returns (bool);

    /**
     * @notice The function to get if the steamer is streaming
     * @param streamerAddress Address of the streamer to watch
     */
    function getStreamerIsStreaming(address streamerAddress)
        external
        view
        returns (bool);

    /**
     * @notice The function to the name of streamer
     * @param streamerAddress Address of the streamer to watch
     */
    function getStreamerName(address streamerAddress)
        external
        view
        returns (string memory);

    /**
     * @notice The function to the number of steams
     * @param streamerAddress Address of the streamer to watch
     */
    function getStreamerNumberOfStreams(address streamerAddress)
        external
        view
        returns (uint256);

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
        returns (string memory);

    /**
     * @notice The function to call as a watcher to stop payment
     * @param streamerAddress Address of the streamer to watch
     */
    function stopWatchingStreamer(address streamerAddress) external;

    /**
     * @notice The function to call as a watcher to get back the currently active stream
     * @param streamerAddress Address of the streamer to watch
     * @return streamId
     */
    function getWatcherStreamId(address streamerAddress)
        external
        view
        returns (string memory);

    /**
     * @notice The function to call as a watcher to get back the name of the currently active stream
     * @param streamerAddress Address of the streamer to watch
     * @return streamId
     */
    function getWatcherStreamName(address streamerAddress)
        external
        view
        returns (string memory);
}
