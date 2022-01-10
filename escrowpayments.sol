// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

struct Item{
    string itemname;
    uint quantity;
    uint price;
    string status;
    address payable buyer_addr;
}

contract EscrowPayments {
    address payable public owner;
    Item[] public ItemList;
    uint ttp_set = 0;
    address public ttp;

    constructor() {
        owner = payable(msg.sender);
    }

    //Function to add item 
    function AddItem(string memory n,uint  pr) public {
        //Only the owner of the contract can sell stuff - personal online store 
        if(msg.sender == owner){
            Item memory tempitem = Item(n, 1 ,pr,  'A', payable(0));
            ItemList.push(tempitem);
        }
    }

    function searchItem(string memory itemtitle) public view returns (uint){
        uint ind = 9999;
        //search for item based on item name 
        for (uint i = 0; i < ItemList.length; i++){
            if(keccak256(bytes(ItemList[i].itemname)) == keccak256(bytes(itemtitle))){
                ind = i;
                break;
            }
        }
        return ind;
    }
    //To buy item
    function BuyItem(string memory itemtitle) public payable{
        uint ind = searchItem(itemtitle);
        if (ind >= 0 && ind < ItemList.length){
            if(msg.value >= ItemList[ind].price && keccak256(bytes(ItemList[ind].status)) == keccak256(bytes('A'))){
                //Store Buyer's Address so that in case of refund money can be returned
                ItemList[ind].buyer_addr = payable(msg.sender);
                //Change Item's Status to Pending i.e 'P'
                ItemList[ind].status = 'P';
            }
        }
    }

    //Can be called by anyone to view items and check avaiability and all
    function listItems() public view returns (Item[] memory) {
        return ItemList;
    }

    //Since it is an escrow payment add TTP - third party
    function addTTP(address addr) public{
        if(msg.sender == owner && ttp_set == 0){
            ttp = addr;
            ttp_set = 1;
        }
    }

    //Buyer can confirm purchase after receiving item 
    function confirmPurchase(string memory title, bool goodorbad) public{
        uint ind = searchItem(title);
        if(ind >= 0 && ind < ItemList.length){
            if (ItemList[ind].buyer_addr == msg.sender){
                if(goodorbad == true){
                    //Change status from Pending(P) to Confirmed(C)
                    ItemList[ind].status = 'C';
                    //Reduce quantity as item is now sold
                    ItemList[ind].quantity -= 1;
                }
                else{
                    //Change status from Pending(P) to Disputed(D)
                    ItemList[ind].status = 'D';
                }
            }
        }
    }

    //Dispute handled externally but update in blockchain but TTP
    function handleDispute(string memory title, string memory st) public{
        if (msg.sender == ttp){
            uint ind = searchItem(title);
           if(ind >= 0 && ind < ItemList.length && keccak256(bytes(ItemList[ind].status)) == keccak256(bytes('D'))){
               if(keccak256(bytes(st)) == keccak256(bytes('C')) || keccak256(bytes(st)) == keccak256(bytes('R'))){
                   ItemList[ind].status = st;
               }
            }
        }
    }

    //function to withdraw amount which can only be called by owner or buyer of the item
    function receivePayment(string memory title) public{
        uint ind = searchItem(title);
        if(msg.sender == ItemList[ind].buyer_addr){
            if (keccak256(bytes(ItemList[ind].status)) == keccak256(bytes('R'))){
                ItemList[ind].buyer_addr.transfer(ItemList[ind].price * (1 ether));
                //If buyer bought item then it is expired and no longer available
                ItemList[ind].status = 'E';
            }
        }
        if (msg.sender == owner){
            if (keccak256(bytes(ItemList[ind].status)) == keccak256(bytes('C'))){
                owner.transfer(ItemList[ind].price * (1 ether));
                //if item is returned it is available
                ItemList[ind].status = 'A';
            }
        }
    }






}
