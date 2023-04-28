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

    // order struct
    struct OrderStruct {
        ItemStruct item;
        address buyer;
        address seller;
        address shipper;
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

    


    // state variables

    address public shipperAddress;
    address public escrow;

    // Deposits
    uint256 public buyerDeposit;
    uint256 public sellerDeposit;

    // fees
    uint256 public escrowFeePercent;
    
    // balances in wallet (after transactions)
    uint256 public escrowBalance;
    uint256 public shippingBalance;


    // products
    uint256 public totalItems = 0;
    uint256 public totalConfirmed = 0;
    uint256 public totalDisputed = 0;

    

    constructor (uint256 _escrowFee, address _shipperAddress) {
        // constructor
        escrow = msg.sender;
        escrowFeePercent = _escrowFee;
        // escrowFeePercent = 5;

        // set the shipper address
        shipperAddress = _shipperAddress;


    } 

    // ITEMS-------------------------------------------------------------

    mapping(uint256 => ItemStruct) public items;
    
    // events
    event ItemCreated(uint256 itemId, uint256 amount);

    // create items
    function createItem(uint256 _amount, uint256 _shippingamount) public {
        totalItems++;
        // calculate totalcost

        items[totalItems] = ItemStruct(totalItems, _amount, _shippingamount, block.timestamp, msg.sender);

        // return success message with item and amount
        emit ItemCreated(totalItems, _amount);
    }

    // view items
    function viewItem(uint256 _itemId) public view returns (uint256, uint256, uint256, uint256, address) {
        return (items[_itemId].itemId, items[_itemId].amount, items[_itemId].shipping_amount, items[_itemId].timestamp, items[_itemId].seller);
    }

    // get total cost of item
    function totalCost(uint256 _itemId) public view returns (uint256) {
        return items[_itemId].amount + items[_itemId].shipping_amount + (items[_itemId].amount * escrowFeePercent) / 100;
    }

    // ORDERS-------------------------------------------------------------

    mapping(uint256 => OrderStruct) public orders;

    // events
    event OrderCreated(uint256 itemId, uint256 amount);


    


    // create order on item purchase
    function createOrder(uint256 _itemId) public payable {

        require(items[_itemId].itemId > 0, "Item does not exist");
        require(items[_itemId].itemId <= totalItems, "Item does not exist");

        // calculate cost of the item + shipping + escrow fee
        uint256 total_cost = totalCost(_itemId);

        require(msg.value == total_cost, string(abi.encodePacked("Incorrect amount sent, please send ", total_cost, " wei")));

        // create order
        orders[_itemId] = OrderStruct(items[_itemId], msg.sender, items[_itemId].seller, shipperAddress, Status.OPEN);

        // calculate buyer deposit
        buyerDeposit = msg.value;


        // return success message with item and amount
        emit OrderCreated(_itemId, msg.value);
    }

    
    // temp struct to view order details
    struct OrderDetails {
        uint256 itemId;
        uint256 amount;
        uint256 shipping_amount; 
        uint256 timestamp;
        address seller;
        address buyer;
        address shipper;
        Status status;
    }
    // view order
    function viewOrder(uint256 _itemId) public view returns (OrderDetails memory) {
        OrderDetails memory order = OrderDetails(
            orders[_itemId].item.itemId,
            orders[_itemId].item.amount,
            orders[_itemId].item.shipping_amount,
            orders[_itemId].item.timestamp,
            orders[_itemId].item.seller,
            orders[_itemId].buyer,
            orders[_itemId].shipper,
            orders[_itemId].status
        );

        return order;
    }


    // confirm order by seller using order id by paying the shipping charges
    function confirmOrder(uint256 _itemId) public payable {
        require(orders[_itemId].item.itemId > 0, "Order does not exist");
        require(orders[_itemId].item.itemId <= totalItems, "Order does not exist");
        require(orders[_itemId].status == Status.OPEN, "Order is not open");
        require(orders[_itemId].item.seller == msg.sender, "Only seller can confirm order");


        // check if shipping amount is paid
        require(msg.value == orders[_itemId].item.shipping_amount, string(abi.encodePacked("Incorrect amount sent, please send ", orders[_itemId].item.shipping_amount, " wei")));

        // update order status
        orders[_itemId].status = Status.CONFIRMED;


        // update seller deposit
        sellerDeposit += msg.value;

        // update total confirmed
        totalConfirmed++;
    }

    // cancel order by buyer using order id
    function cancelOrder(uint256 _itemId) public payable {
        require(orders[_itemId].item.itemId > 0, "Order does not exist");
        require(orders[_itemId].item.itemId <= totalItems, "Order does not exist");
        require(orders[_itemId].buyer == msg.sender, "Only buyer can cancel order");

        // update order status
        orders[_itemId].status = Status.CANCELLED;


        // total cost of item
        uint256 total_cost = totalCost(_itemId);

        // update buyer deposit
        buyerDeposit -= total_cost;

        // refund buyer
        payable(orders[_itemId].buyer).transfer(total_cost);

        // update seller deposit
        sellerDeposit -= orders[_itemId].item.shipping_amount;
        
        // refund seller
        payable(orders[_itemId].item.seller).transfer(orders[_itemId].item.shipping_amount);

    }


}