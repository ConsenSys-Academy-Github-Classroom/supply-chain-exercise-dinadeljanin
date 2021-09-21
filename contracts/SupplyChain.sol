// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract SupplyChain {

    address public owner;
    uint public skuCount;

    mapping (uint => Item) public items;

    enum State {
        ForSale,
        Sold,
        Shipped,
        Received
    }

    struct Item {
        string name;
        uint sku;
        uint price;
        State state;
        address payable seller;
        address payable buyer;
    }

    event LogForSale(uint sku);
    event LogSold(uint sku);
    event LogShipped(uint sku);
    event LogReceived(uint sku);

    constructor() { 
        owner = msg.sender; 
        skuCount = 0;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier verifyCaller(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier paidEnough(uint _price) {
        require(msg.value >= _price);
        _;
    }

    modifier checkValue(uint _sku) {
        _;
        uint _price = items[_sku].price;
        uint amountToRefund = msg.value - _price;
        payable(items[_sku].buyer).transfer(amountToRefund);
    }

    modifier forSale(uint _sku) {
        // What item properties will be non-zero when an Item has been added? -> The seller's address won't be set
        // Could be name and price but someone could pass in an empty str for the name and 0 for the price.
        require(payable(items[_sku].seller) != address(0), "Item doesn't exist");
        require(items[_sku].state == State.ForSale, "Item does exist, but is not for sale.");
        _;
    }

    modifier sold(uint _sku) {
        // Because the state is non-zero, the item exists
        require(items[_sku].state == State.Sold, "Item has not been sold.");
        _;
    }
  
    modifier shipped(uint _sku) {
        require(items[_sku].state == State.Shipped, "Item has not been shipped.");
        _;
    }
    
    modifier received(uint _sku) {
        require(items[_sku].state == State.Received, "Item has not been received with an i before e except after c :clown:.");
        _;
    }

    function addItem(string memory _name, uint _price) public returns (bool) {
        items[skuCount] = Item({
        name: _name,
        sku: skuCount,
        price: _price,
        state: State.ForSale,
        seller: payable(msg.sender),
        buyer: payable(address(0))
        });
        
        skuCount += 1;
        emit LogForSale(skuCount);
        return true;
    }

    function buyItem(uint sku) public payable
        forSale(sku)
        paidEnough(items[sku].price)
        checkValue(sku)
    {
        payable(items[sku].seller).transfer(items[sku].price);
        items[sku].buyer = payable(msg.sender);
        items[sku].state = State.Sold;

        emit LogSold(skuCount);
    }

    function shipItem(uint sku) public 
        sold(sku)
        verifyCaller(items[sku].seller)
    {
        items[sku].state = State.Shipped;
        emit LogShipped(sku);
    }

    function receiveItem(uint sku) public 
        shipped(sku)
        verifyCaller(items[sku].buyer)
    {
        items[sku].state = State.Received;
        emit LogReceived(sku);
    }

     function fetchItem(uint _sku) public view
       returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
     { 
       name = items[_sku].name;
       sku = items[_sku].sku;
       price = items[_sku].price;
       state = uint(items[_sku].state);
       seller = items[_sku].seller;
       buyer = items[_sku].buyer;
       return (name, sku, price, state, seller, buyer);
     }
}
