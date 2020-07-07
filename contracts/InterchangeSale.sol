pragma solidity ^0.4.19;

/* Copyright 2020 (C) FreightTrust and Clearing Corporation - All Rights Reserved
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */
 
import "./SafeMath.sol";
import "./InterchangeToken.sol";
import "./Ownable.sol";

contract EDIToken {
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract InterchangeSaleContract is Ownable{
    InterchangeTokenContract public assetToken; 
    EDIToken public ediToken;
    address public beneficiaryAddress;
    uint256 internal EDIPerToken = 1 * 10 ** 18;
    /// @dev TODO: Audit the Math for proceeding section
    /// @dev Must have set allowance for sale contract
    /// @dev TODO: Audit hasAllowance struct
    modifier hasAllowance () {
       
        require(ediToken.allowance(msg.sender, address(this)) >= EDIPerToken);
        _;
    }
    
    modifier onlyOwnerOf(uint256 _licenseId) {
        require(assetToken.ownerOf(_licenseId) == msg.sender);
        _;
    }
    
    constructor (InterchangeTokenContract _assetTokenAddress, EDIToken _ediToken, address _beneficiary) public {
        assetToken = _assetTokenAddress;
        ediToken = _ediToken;
        beneficiaryAddress = _beneficiary;
    }
    
    function setBeneficiaryAddress (address _beneficiary) public onlyOwner returns (address){
        require(_beneficiary != address(0));
        beneficiaryAddress = _beneficiary;
        return beneficiaryAddress;
    }
    
    function getBeneficiaryAddress () public view returns (address) {
        return beneficiaryAddress;
    }

    function setEDITokenAddress (EDIToken _aryAddress) public onlyOwner returns (address){
        require(_aryAddress != address(0));
        ediToken = _aryAddress;
        return ediToken;
    }
    
    function getEDIAddress () public view returns (EDIToken) {
        return ediToken;
    }

    function setTokenAddress (InterchangeTokenContract _tokenAddress) public onlyOwner returns (address){
        require(_tokenAddress != address(0));
        assetToken = _tokenAddress;
        return assetToken;
    }
    
    function getTokenAddress () public view returns (InterchangeTokenContract) {
        return assetToken;
    }
    
    function setEDIPerToken (uint256 _aryPerToken) public onlyOwner returns (uint256){
        require(_aryPerToken >= 1);
        EDIPerToken = _aryPerToken;
        return EDIPerToken;
    }
    
    function getEDIPerToken () public view returns (uint256) {
        return EDIPerToken;
    }
    
    function makePayment () private returns (bool) {
        return ediToken.transferFrom(msg.sender, beneficiaryAddress, EDIPerToken);
    }
    
    function purchase(string _companyId, address[] _whitelistedAddresses, address _assignee) external hasAllowance returns (uint) {
        require(_assignee != address(0));
        
        /// @dev Transfer EDITokens from sender account to beneficiaryAddress
        /// @dev TODO: Audit this section 
        /// @dev DESIGN: integrate point for staking pool distribution (cont)
        /// as payments made for this are deposited between company and token stakers (EDI staking)
        require(makePayment());

        uint256 assetId = assetToken.mint(_assignee, _companyId, _whitelistedAddresses);
        return assetId;
    }
    
    function findAddress(address[] haystack, address needle) pure internal returns(uint256){
        for (uint256 i = 0; i < haystack.length; i++){
            if (needle == haystack[i]) {
                return i;
            }
        }
        return haystack.length;
    }    
    
    function addLicenseWhitelistedAddress(uint256 _licenseId, address _whitelistedAddress) public onlyOwnerOf(_licenseId) returns (address[]){
        require(assetToken.isValidLicense(_licenseId));
        require(_whitelistedAddress != address(0));
        
        address[] memory existingAddress = assetToken.getLicenseWhitelistedAddresses(_licenseId);
        uint256 addressIndex = findAddress(existingAddress, _whitelistedAddress);
        
        if (addressIndex < existingAddress.length) {
            return existingAddress;
        }
        
        return assetToken.addLicenseWhitelistedAddress(_licenseId, _whitelistedAddress);
    }
    
    function addLicenseWhitelistedAddressBulk(uint256 _licenseId, address[] _whitelistedAddresses) public onlyOwnerOf(_licenseId) returns (address[]){
        require(assetToken.isValidLicense(_licenseId));
        require(_whitelistedAddresses.length > 0);
        
        address[] memory existingAddresses = assetToken.getLicenseWhitelistedAddresses(_licenseId);
        for(uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            uint256 addressIndex = findAddress(existingAddresses, _whitelistedAddresses[i]);
            if (addressIndex < existingAddresses.length) {
                delete _whitelistedAddresses[addressIndex];
            }
        }
        
        return assetToken.addLicenseWhitelistedAddressBulk(_licenseId, _whitelistedAddresses);
    }
    
    function removeLicenseWhitelistedAddress(uint256 _licenseId, address _whitelistedAddress) public onlyOwnerOf(_licenseId) returns (address[]){
        require(assetToken.isValidLicense(_licenseId));
        require(_whitelistedAddress != address(0));
        
        address[] memory existingAddresses = assetToken.getLicenseWhitelistedAddresses(_licenseId);
        uint256 addressIndex = findAddress(existingAddresses, _whitelistedAddress);
        if (addressIndex >= existingAddresses.length) {
            return existingAddresses;
        }
        
        return assetToken.removeLicenseWhitelistedAddress(_licenseId, _whitelistedAddress);
    }
    
    function removeLicenseWhitelistedAddressBulk(uint256 _licenseId, address[] _whitelistedAddresses) public onlyOwnerOf(_licenseId) returns (address[]){
        require(assetToken.isValidLicense(_licenseId));
        require(_whitelistedAddresses.length > 0);

        return assetToken.removeLicenseWhitelistedAddressBulk(_licenseId, _whitelistedAddresses);
    }

    
    function renew(uint256 _licenseId) external hasAllowance onlyOwnerOf(_licenseId) returns (bool) {
        /// @dev Transfer EDITokens from sender account to beneficiaryAddress
        require(makePayment());

        return assetToken.renew(_licenseId);
    }
}