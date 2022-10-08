pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {ISuperfluid, ISuperToken, ISuperApp} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {ISuperfluidToken} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluidToken.sol";
import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";

// Local interfaces
import "../interfaces/ISubscriptionHandler.sol";

contract SubscriptionHandler is Ownable, Pausable, ISubscriptionHandler {
    // // // // // // // // // // // // // // // // // // // //
    // LIBRARIES AND STRUCTS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice CFA Library.
     */
    using CFAv1Library for CFAv1Library.InitData;
    CFAv1Library.InitData public cfaV1;

    // // // // // // // // // // // // // // // // // // // //
    // VARIABLES
    // // // // // // // // // // // // // // // // // // // //

    address private _controller;

    // // // // // // // // // // // // // // // // // // // //
    // CONSTRUCTOR
    // // // // // // // // // // // // // // // // // // // //

    constructor(ISuperfluid host, address _newController) {
        assert(address(host) != address(0));
        _controller = _newController;

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

    modifier onlyControllerOrOwner() {
        require(
            _msgSender() != _controller && _msgSender() != owner(),
            "Must be a controller or owner"
        );
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

    // // // // // // // // // // // // // // // // // // // //
    // OWNER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice Pause this contract
     * @param val Pause state to set
     */
    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    /**
     * @notice Transfer controller address.
     * @param _newController New controller account.
     */
    function changeController(address _newController)
        external
        override
        onlyOwner
    {
        address _oldController = _controller;
        _controller = _newController;

        emit ChangedController(_msgSender(), _oldController, _newController);
    }

    // // // // // // // // // // // // // // // // // // // //
    // CONTROLLER FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @dev Allow the user to let the contract create inifinite streams of value on their behalf
     * @param tokenAddress Super token address
     */
    function authorizeFullFlow(address tokenAddress)
        external
        override
        whenNotPaused
    {
        cfaV1.authorizeFlowOperatorWithFullControl(
            ISuperfluidToken(tokenAddress),
            address(this),
            new bytes(0)
        );

        emit AuthorizedFullFlow(_msgSender(), address(this), tokenAddress);
    }

    // // // // // // // // // // // // // // // // // // // //
    // BASE FUNCTIONS
    // // // // // // // // // // // // // // // // // // // //

    /**
     * @notice Create a stream into the streamer.
     * @dev This requires the caller to be the controller contract
     * @param tokenAddress Token to stream.
     * @param flowRate Flow rate per second to stream.
     * @param fromAddress The sending address of the stream.
     * @param toAddress The receiving address of the stream.
     */
    function createSubscriptionFlow(
        address tokenAddress,
        int96 flowRate,
        address fromAddress,
        address toAddress
    ) external override whenNotPaused onlyControllerOrOwner {
        cfaV1.createFlowByOperator(
            fromAddress,
            toAddress,
            ISuperfluidToken(tokenAddress),
            flowRate
        );
        emit CreatedSubscriptionFlow(
            _msgSender(),
            fromAddress,
            toAddress,
            tokenAddress,
            flowRate
        );
    }

    /**
     * @notice Delete a stream that the sender is sending
     * @param tokenAddress Token address to quit streaming.
     * @param fromAddress The sending address of the stream.
     * @param toAddress The receiving address of the stream.
     */
    function deleteSubscriptionFlow(
        address tokenAddress,
        address fromAddress,
        address toAddress
    ) external override whenNotPaused onlyControllerOrOwner {
        cfaV1.deleteFlow(
            fromAddress,
            toAddress,
            ISuperfluidToken(tokenAddress)
        );
        emit DeletedSubscriptionFlow(
            _msgSender(),
            fromAddress,
            toAddress,
            tokenAddress
        );
    }
}
