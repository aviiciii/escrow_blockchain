// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;


// escrow contract

contract Escrow {

    struct ItemStruct {
        uint256 itemId;
        uint256 amount;
        uint256 timestamp;
        address owner;
        Status status;
        bool confirmed;
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

    uint256 public escrowFee;
    uint256 public escrowBalance;


    // products
    uint256 public totalItems = 0;
    uint256 public totalConfirmed = 0;
    uint256 public totalDisputed = 0;

    

    constructor (uint256 _escrowFee) {
        // constructor
        escrow = msg.sender;
        escrowFee = _escrowFee;
    } 

}