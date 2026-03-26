// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EnhancedSimpleEscrow {
    enum EscrowState { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE, DISPUTED, CANCELLED }
    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;
    uint256 public amount;
    EscrowState public state;

    uint256 public immutable deliveryTimeout;

    constructor(address _seller, address _arbiter, uint256 _deliveryTimeout) {
        deliveryTimeout = _deliveryTimeout;
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        state = EscrowState.AWAITING_PAYMENT;
    }

    function deposit() external payable {
        require(msg.sender == buyer && state == EscrowState.AWAITING_PAYMENT);
        amount = msg.value;
        state = EscrowState.AWAITING_DELIVERY;
    }

    function confirmDelivery() external {
        require(msg.sender == buyer && state == EscrowState.AWAITING_DELIVERY);
        state = EscrowState.COMPLETE;
        (bool success, ) = payable(seller).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function raiseDispute() external {
        require(msg.sender == buyer || msg.sender == seller);
        state = EscrowState.DISPUTED;
    }

    function resolveDispute(bool _releaseToSeller) external {
        require(msg.sender == arbiter && state == EscrowState.DISPUTED);
        state = EscrowState.COMPLETE;
        (bool success, ) = payable(_releaseToSeller ? seller : buyer).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function cancel() external {
        require(msg.sender == buyer, "Buyers only");
        require(state == EscrowState.AWAITING_DELIVERY, "Cannot cancel");
        require(block.timestamp > deliveryTimeout, "Timeout not reached");

        state = EscrowState.CANCELLED;

        (bool success, ) = payable(buyer).call{value: amount}("");
        require(success, "Transfer failed");
    }
}