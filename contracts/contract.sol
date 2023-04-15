// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;


// escrow contract

contract Escrow {

    struct ItemStruct {
        uint256 itemId;
        uint256 amount;
        uint256 timestamp;
        address seller;
        Status status;
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
    function createItem(uint256 _amount) public {
        totalItems++;
        items[totalItems] = ItemStruct(totalItems, _amount, block.timestamp, msg.sender, Status.OPEN);
    }

    // view items
    function viewItem(uint256 _itemId) public view returns (uint256, uint256, uint256, address, Status) {
        return (items[_itemId].itemId, items[_itemId].amount, items[_itemId].timestamp, items[_itemId].seller, items[_itemId].status);
    }
}