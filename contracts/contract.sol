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
        uint256 orderId;
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
        REJECTED,
        DELIVERED,
        DISPUTED,
        DISPUTED_RESOLVED_BUYER_MISTAKE,
        DISPUTED_RESOLVED_SELLER_MISTAKE
    }



    // state variables

    address shipperAddress;
    address escrow;

    // Deposits
    uint256 public buyerDeposit;
    uint256 public sellerDeposit;

    // fees
    uint256 escrowFeePercent;
    
    // balances in wallet (after transactions)
    uint256 public escrowBalance;
    uint256 public shippingBalance;


    // products
    uint256 public totalItems = 0;
    uint256 public totalOrders = 0;
    uint256 public totalConfirmed = 0;
    uint256 public totalDisputed = 0;
    uint256 public totalDelivered = 0;

    

    constructor (uint256 _escrowFee, address _shipperAddress) {
        // constructor
        escrow = msg.sender;
        escrowFeePercent = _escrowFee;
        // escrowFeePercent = 5;

        // set the shipper address
        shipperAddress = _shipperAddress;


    } 

    // check contract balance
    function checkBalance() public view returns (uint256) {
        return (address(this).balance);
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
        // buyer must not be seller
        require(items[_itemId].seller != msg.sender, "Buyer cannot be seller");

        // calculate cost of the item + shipping + escrow fee
        uint256 total_cost = totalCost(_itemId);

        require(msg.value == total_cost, string(abi.encodePacked("Incorrect amount sent, please send ", total_cost, " wei")));

        // order id
        uint256 orderId = totalOrders + 1;

        // create order
        orders[orderId] = OrderStruct(orderId, items[_itemId], msg.sender, items[_itemId].seller, shipperAddress, Status.OPEN);

        // calculate buyer deposit
        buyerDeposit = msg.value;

        // update total orders
        totalOrders++;

        // return success message with item and amount
        emit OrderCreated(_itemId, msg.value);
    }

    
    // temp struct to view order details
    struct OrderDetails {
        uint orderId;
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
    function viewOrder(uint256 _orderId) public view returns (OrderDetails memory) {
        OrderDetails memory order = OrderDetails(
            orders[_orderId].orderId,
            orders[_orderId].item.itemId,
            orders[_orderId].item.amount,
            orders[_orderId].item.shipping_amount,
            orders[_orderId].item.timestamp,
            orders[_orderId].item.seller,
            orders[_orderId].buyer,
            orders[_orderId].shipper,
            orders[_orderId].status
        );

        return order;
    }

    
    // confirm order by seller using order id by paying the shipping charges
    function confirmOrder(uint256 _orderId) public payable {
        require(_orderId > 0, "Order does not exist");
        require(_orderId <= totalOrders, "Order does not exist");

        require(orders[_orderId].status == Status.OPEN, "Order is not open");
        require(orders[_orderId].item.seller == msg.sender, "Only seller can confirm order");


        // check if shipping amount is paid
        require(msg.value == orders[_orderId].item.shipping_amount, string(abi.encodePacked("Incorrect amount sent, please send ", orders[_orderId].item.shipping_amount, " wei")));

        // update order status
        orders[_orderId].status = Status.CONFIRMED;

        // update seller deposit
        sellerDeposit += msg.value;

        // escrow balance from buyer deposit
        escrowBalance += (orders[_orderId].item.amount * escrowFeePercent) / 100;
        buyerDeposit -= (orders[_orderId].item.amount * escrowFeePercent) / 100;

        // update total confirmed
        totalConfirmed++;
    }

    // deliver order by shipper using order id
    function deliveredOrder(uint256 _orderId) public {
        require(_orderId > 0, "Order does not exist");
        require(_orderId <= totalItems, "Order does not exist");
        require(orders[_orderId].shipper == msg.sender, "Only shipper can deliver order");
        require(orders[_orderId].status == Status.CONFIRMED, "Order is not confirmed");

        // update order status
        orders[_orderId].status = Status.DELIVERED;
        
        // // pay shipper the shipping amount
        // payable(orders[_orderId].shipper).transfer(orders[_orderId].item.shipping_amount);

        // // pay seller the item amount and shipping amount (deposit)
        // payable(orders[_orderId].item.seller).transfer(orders[_orderId].item.amount + orders[_orderId].item.shipping_amount);
        
        // // update deposit
        // sellerDeposit -= orders[_orderId].item.shipping_amount;
        // buyerDeposit -= orders[_orderId].item.amount + orders[_orderId].item.shipping_amount;

        // update total confirmed
        totalConfirmed--;

        // update total delivered
        totalDelivered++;
    }

    // cancel the order
    function cancelOrder(uint256 _orderId) public payable {
        // check if order exists
        require(_orderId > 0, "Order does not exist");
        require(_orderId <= totalOrders, "Order does not exist");

        // check if buyer or seller
        require(orders[_orderId].buyer == msg.sender || orders[_orderId].seller == msg.sender, "Only buyer or seller can cancel order");

        // check current status open or confirmed
        require(orders[_orderId].status == Status.OPEN || orders[_orderId].status == Status.CONFIRMED, "Order cannot be cancelled");
        
        if (orders[_orderId].buyer == msg.sender) {
            // if buyer cancels order
            if (orders[_orderId].status == Status.OPEN) {
                // update order status
                orders[_orderId].status = Status.CANCELLED;

                // refund buyer (item amount + shipping amount)
                payable(orders[_orderId].buyer).transfer(orders[_orderId].item.amount + orders[_orderId].item.shipping_amount);

                // update buyer deposit (total cost)
                buyerDeposit -= totalCost(orders[_orderId].item.itemId);

                // update escrow balance (escrow fee)
                escrowBalance += (orders[_orderId].item.amount * escrowFeePercent) / 100;


            } else if (orders[_orderId].status == Status.CONFIRMED) {
                // update order status
                orders[_orderId].status = Status.CANCELLED;

                // refund buyer (item amount only)
                payable(orders[_orderId].buyer).transfer(orders[_orderId].item.amount);

                // update buyer deposit (item amount + shipping amount)
                buyerDeposit -= (orders[_orderId].item.amount + orders[_orderId].item.shipping_amount);

                // update seller deposit (shipping amount)
                sellerDeposit -= orders[_orderId].item.shipping_amount;

                // refund seller (shipping amount)
                payable(orders[_orderId].item.seller).transfer(orders[_orderId].item.shipping_amount);

                // pay shipper the shipping amount from buyer deposit
                payable(orders[_orderId].shipper).transfer(orders[_orderId].item.shipping_amount);
            } else {
                revert("Order cannot be cancelled");
            }
        } else if (orders[_orderId].seller == msg.sender) {
            // if seller cancels order
            if (orders[_orderId].status == Status.OPEN) {
                // update order status
                orders[_orderId].status = Status.REJECTED;

                // refund buyer (total cost)
                payable(orders[_orderId].buyer).transfer(totalCost(orders[_orderId].item.itemId));

                // update buyer deposit (total cost)
                buyerDeposit -= totalCost(orders[_orderId].item.itemId);

                // no escrow fee


            } else if (orders[_orderId].status == Status.CONFIRMED) {
                // update order status
                orders[_orderId].status = Status.REJECTED;

                // refund buyer (total cost)
                payable(orders[_orderId].buyer).transfer(totalCost(orders[_orderId].item.itemId));

                // update buyer deposit (total cost)
                buyerDeposit -= orders[_orderId].item.amount + orders[_orderId].item.shipping_amount;
                escrowBalance -= (orders[_orderId].item.amount * escrowFeePercent) / 100;

                // update seller deposit (shipping amount)
                sellerDeposit -= orders[_orderId].item.shipping_amount;

                // pay shipper the shipping amount from seller deposit
                payable(orders[_orderId].shipper).transfer(orders[_orderId].item.shipping_amount);

            } else {
                revert("Order cannot be cancelled");
            }
        } else {
            revert("Order cannot be cancelled");
        }
    }

    // dispute the order by buyer
    function disputeOrder(uint256 _orderId) public  {
        // check if order exists
        require(_orderId > 0, "Order does not exist");
        require(_orderId <= totalOrders, "Order does not exist");

        // check if buyer
        require(orders[_orderId].buyer == msg.sender, "Only buyer can dispute order");

        // check current status open or confirmed
        require(orders[_orderId].status == Status.DELIVERED, "Order cannot be disputed");

        // update order status
        orders[_orderId].status = Status.DISPUTED;
    }

    // resolve the dispute by shipper
    function resolveDispute(uint256 _orderId, bool _buyerMistake, bool _sellerMistake) public payable {
        // check if order exists
        require(_orderId > 0, "Order does not exist");
        require(_orderId <= totalOrders, "Order does not exist");

        // check if shipper
        require(orders[_orderId].shipper == msg.sender, "Only shipper can resolve dispute");

        // check current status open or confirmed
        require(orders[_orderId].status == Status.DISPUTED, "Order cannot be resolved");

        // update order status
        if (_buyerMistake) {
            // buyer mistake
            orders[_orderId].status = Status.DISPUTED_RESOLVED_BUYER_MISTAKE;

            // refund buyer (item amount)
            payable(orders[_orderId].buyer).transfer(orders[_orderId].item.amount);
            buyerDeposit -= orders[_orderId].item.amount+orders[_orderId].item.shipping_amount;

            // refund seller (shipping amount)
            payable(orders[_orderId].item.seller).transfer(orders[_orderId].item.shipping_amount);
            sellerDeposit -= orders[_orderId].item.shipping_amount;

            // pay shipper the shipping amount from buyer deposit
            payable(orders[_orderId].shipper).transfer(orders[_orderId].item.shipping_amount);



        } else if (_sellerMistake) {
            // seller mistake
            orders[_orderId].status = Status.DISPUTED_RESOLVED_SELLER_MISTAKE;
            
            // refund buyer (item amount + shipping amount)
            payable(orders[_orderId].buyer).transfer(orders[_orderId].item.amount + orders[_orderId].item.shipping_amount);
            buyerDeposit -= orders[_orderId].item.amount + orders[_orderId].item.shipping_amount;

            // pay shipper the shipping amount from seller deposit
            payable(orders[_orderId].shipper).transfer(orders[_orderId].item.shipping_amount);
            sellerDeposit -= orders[_orderId].item.shipping_amount;

        } else {
            revert("Order cannot be resolved");
        }
    }











    
}