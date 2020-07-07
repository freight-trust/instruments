pragma solidity ^0.4.19;
pragma experimental ABIEncoderV2;


/* Copyright 2020 (C) FreightTrust and Clearing Corporation - All Rights Reserved
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
 
import "./SafeMath.sol";
import "./ERC721BasicToken.sol";
import "./Bill.sol";
import "./InterchangeToken.sol";

contract InterchangeTokenContractInterface {
    function hasInterchangeAccess (address _whitelistedAddress, string _companyId) public view returns (bool);
}

contract InterchangeBillOfLadingContract is BillContract, ERC721BasicTokenContract{
    using SafeMath for uint256;
    InterchangeTokenContractInterface public assetToken; 
    
    modifier onlyWithAccess (string _comapnyId) {
        require(hasInterchangeAccess(_comapnyId));
        _;    
    }
    
    constructor(string _name, string _symbol, InterchangeTokenContractInterface _tokenAddress) ERC721BasicTokenContract(_name, _symbol) public {
        assetToken = _tokenAddress;
    }
    
    function hasInterchangeAccess (string _comapnyId) public view returns (bool){
        return assetToken.hasInterchangeAccess(msg.sender, _comapnyId);
    }
    
    function setTokenAddress (InterchangeTokenContractInterface _tokenAddress) public onlyOwner returns (address){
        require(_tokenAddress != address(0));
        assetToken = _tokenAddress;
        return assetToken;
    }
    
    function getTokenAddress () public view returns (InterchangeTokenContractInterface) {
        return assetToken;
    }
    
    function createBill(string quoteId, string _companyId) onlyWithAccess(_companyId) public returns (uint256 _tokenId){
        bills.length++;
        Bill storage bill = bills[bills.length - 1];
        bill.quoteId = quoteId;
        bill.carrier_address = msg.sender;
        bill.companyId = _companyId;

        /// @dev TODO: audit questionable here
        /// for (uint i = 0; i < items.length; i++){
        ///     bill.items.push(items[i]);
        /// }
        
        _tokenId = bills.length - 1;
        _mint(msg.sender, _tokenId);
        emit BillCreated(msg.sender, _tokenId, quoteId);
    }
    
    function addItem(uint256 _billId, Item item) onlyOwnerOf(_billId) public returns (Item[]) {
        Bill storage bill = bills[_billId];
        bill.items.push(item);
        return bill.items;
    }
}