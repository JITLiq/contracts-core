// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ISourceOpStateManager} from "src/interfaces/ISourceOpStateManager.sol";
import {IEntity} from "src/interfaces/IEntity.sol";
import {AddressRegistryService} from "src/core/AddressRegistryService.sol";

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

contract SourceOpStateManager is ISourceOpStateManager, AddressRegistryService {
    using SafeTransferLib for address;

    error AlreadyRegistered();
    error NotRegistered();
    error InsufficientFunds();
    error OnlyEntrypoint();

    event OperatorStaked(address indexed operator, uint256 stakeAmount);
    event WithdrawalInitiated(address indexed operator, uint256 withdrawAmount);
    event OrderCreated(bytes32 indexed orderId);
    event OrderFulfilled(bytes32 indexed orderId);

    uint256 public constant LP_FEE = 7000;
    uint256 public constant OPERATOR_FEE = 3000;
    uint256 public constant MAX_BPS = 10000;

    constructor(address _addressRegistry) AddressRegistryService(_addressRegistry) {}

    mapping(address => OperatorData) public operatorData;
    mapping(bytes32 => OrderData) public orderData;
    mapping(address => uint256) lpRefundPending;

    function baseBridgeToken() public view returns (address) {
        return _getAddress(_BASE_BRIDGE_TOKEN);
    }

    function registerOperator(uint256 stakeAmount) external {
        address _op = msg.sender;
        if (operatorData[_op].registered) revert AlreadyRegistered();

        _pullOperatorFunds(stakeAmount, _op);
    }

    function increaseStake(uint256 stakeAmount) external {
        address _op = msg.sender;
        if (operatorData[_op].registered) revert NotRegistered();

        _pullOperatorFunds(stakeAmount, _op);
    }

    function withdrawStake(uint256 withdrawAmount) external {
        address _op = msg.sender;
        if (operatorData[_op].registered) revert NotRegistered();

        uint256 _operatorLiquidFund = operatorData[_op].currentStake - operatorData[_op].currentHolding;
        if (_operatorLiquidFund < withdrawAmount) revert InsufficientFunds();

        emit WithdrawalInitiated(_op, withdrawAmount);
    }

    function syncOperator(address operator, OperatorData memory newOperatorData, bool deleteOperator) external {
        _onlyGov(msg.sender);

        if (deleteOperator) {
            delete operatorData[operator];
            return;
        }

        operatorData[operator] = newOperatorData;
    }

    function sweep(address token, uint256 amount) external {
        _onlyGov(msg.sender);

        token.safeTransfer(msg.sender, amount);
    }

    function updateOperatorAllocation(address operator, uint256 holdingAmount, uint256 stakeAmount, bool init)
        external
    {
        _onlyEntrypoint(msg.sender);
        if (!operatorData[operator].registered) revert NotRegistered();

        if (init) {
            operatorData[operator].currentHolding += holdingAmount;
        } else {
            operatorData[operator].currentHolding -= holdingAmount;
            operatorData[operator].currentStake += stakeAmount;
        }
    }

    function createOrder(
        bytes32 orderId,
        uint32 expiry,
        uint256 orderAmount,
        address destAddress,
        address operator,
        uint256 operationFee,
        uint256 bridgeFee
    ) external {
        _onlyEntrypoint(msg.sender);
        if (orderData[orderId].fulfilled || orderData[orderId].orderAmount != 0) {
            revert AlreadyRegistered();
        }
        if (operatorData[operator].currentHolding < orderAmount || orderAmount == 0) revert InsufficientFunds();

        orderData[orderId] = OrderData({
            fulfilled: false,
            expiry: expiry,
            orderAmount: orderAmount,
            destAddress: destAddress,
            operator: operator,
            fees: FeesData({operationFee: operationFee, bridgeFee: bridgeFee})
        });

        emit OrderCreated(orderId);
    }

    function completeOrder(bytes32 orderId) external {
        _onlyEntrypoint(msg.sender);
        if (orderData[orderId].orderAmount == 0) revert NotRegistered();

        orderData[orderId].fulfilled = true;
        emit OrderFulfilled(orderId);
    }

    function updatePendingRefunds(FulfillerData[] memory fulfillerData, uint256 lpFees) external {
        _onlyEntrypoint(msg.sender);

        uint256 fulfillersLength = fulfillerData.length;
        while (fulfillersLength != 0) {
            FulfillerData memory _fulfillerData = fulfillerData[fulfillersLength - 1];
            lpRefundPending[_fulfillerData.fulfiller] += (_fulfillerData.fulfillAmount + lpFees);

            unchecked {
                fulfillersLength--;
            }
        }
    }

    function _pullOperatorFunds(uint256 _stakeAmount, address _op) internal {
        baseBridgeToken().safeTransferFrom(_op, address(this), _stakeAmount);
        OperatorData memory _operatorData = operatorData[_op];

        operatorData[_op] =
            OperatorData({currentStake: _operatorData.currentStake + _stakeAmount, currentHolding: 0, registered: true});
        emit OperatorStaked(_op, _stakeAmount);
    }

    function _onlyEntrypoint(address _addr) internal view {
        if (_addr != _getAddress(_SOURCE_ENTRYPOINT_HASH)) {
            revert OnlyEntrypoint();
        }
    }
}
