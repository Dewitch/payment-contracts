pragma solidity ^0.8.2;

interface ISubscriptionHandler {
    // // // // // // // // // // // // // // // // // // // //
    // EVENTS
    // // // // // // // // // // // // // // // // // // // //

    // // // // // // // // // // // // // // // // // // // //
    // OWNER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice Owner function to update the subscription handler contract reference
     * @param _newSubscriptionHandlerAddress Address of the new subscription contract
     */
    function setSubscriptionHandler(address _newSubscriptionHandlerAddress)
        external;

    // // // // // // // // // // // // // // // // // // // //
    // VIEW FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice View function to get the list streamers
     */
    function streamers() external view returns (string[] memory);

    // // // // // // // // // // // // // // // // // // // //
    // STREAMER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice The first function that streamers need to call to get started
     * @param streamerName String representation of what streamers want to be called
     */
    function registerAsStream(string memory streamerName) external;

    /**
     * @notice The function to call to begin a stream, can only have one stream at a time
     * @param streamId String of the stream
     */
    function startStream(string memory streamId) external;

    /**
     * @notice The function to call to end the active stream
     */
    function endStream() external;

    /**
     * @notice The function to call to get back the currently active stream
     */
    function getMyActiveStream() external view returns (string memory);

    // // // // // // // // // // // // // // // // // // // //
    // WATCHER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice The function to call as a watcher to start payment and get back the currently active stream
     * @param streamerAddress Address of the streamer to watch
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
     */
    function getStreamId(address streamerAddress)
        external
        view
        returns (string memory);
}
