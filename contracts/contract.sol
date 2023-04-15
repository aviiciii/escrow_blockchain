// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;


// escrow contract

contract Escrow {

    struct ItemStruct {
        uint256 itemId;
        uint256 amount;
        uint256 shipping_amount;
        uint256 timestamp;
        address seller;
    }

    enum Status {
        OPEN,
        CONFIRMED,
        CANCELLED,
        DELIVERED,
        DISPUTED_BY_BUYER, // BUYER MISTAKE
        DISPUTED_BY_SELLER // SELLER MISTAKE
    }

    mapping(uint256 => ItemStruct) public items;


    // state variables

    address public buyer;
    address public seller;
    address public shipper;
    address public escrow;

    uint256 public buyerDeposit;
    uint256 public sellerDeposit;

    uint256 public escrowFeePercent;
    uint256 public escrowBalance;


    // products
    uint256 public totalItems = 0;
    uint256 public totalConfirmed = 0;
    uint256 public totalDisputed = 0;

    

    constructor (uint256 _escrowFee) {
        // constructor
        escrow = msg.sender;
        escrowFeePercent = _escrowFee;
        // escrowFeePercent = 5;

    } 

    // create items
    function createItem(uint256 _amount, uint256 _shippingamount) public {
        totalItems++;
        items[totalItems] = ItemStruct(totalItems, _amount, _shippingamount, block.timestamp, msg.sender);
    }

    // view items
    function viewItem(uint256 _itemId) public view returns (uint256, uint256, uint256, uint256, address) {
        return (items[_itemId].itemId, items[_itemId].amount, items[_itemId].shipping_amount, items[_itemId].timestamp, items[_itemId].seller);
    }


    // order struct
    struct OrderStruct {
        ItemStruct item;
        address buyer;
        address seller;
        address shipper;
        Status status;
    }

    mapping(uint256 => OrderStruct) public orders;

    // create order
    function createOrder(uint256 _itemId) public {
        orders[_itemId] = OrderStruct(items[_itemId], msg.sender, items[_itemId].seller, address(0), Status.OPEN);
    }

    // view order
    function viewOrder(uint256 _itemId) public view returns (uint256, uint256, uint256, uint256, address, Status, address, address, address, Status) {
        return (orders[_itemId].item.itemId, orders[_itemId].item.amount, orders[_itemId].item.shipping_amount, orders[_itemId].item.timestamp, orders[_itemId].item.seller, orders[_itemId].item.status, orders[_itemId].buyer, orders[_itemId].seller, orders[_itemId].shipper, orders[_itemId].status);
    }



}