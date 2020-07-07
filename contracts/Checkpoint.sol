pragma solidity ^0.4.19;
pragma experimental ABIEncoderV2;


/* Copyright 2020 (C) FreightTrust and Clearing Corporation - All Rights Reserved
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

 
import './SafeMath.sol';
import "./ERC721BasicToken.sol";
import "./Ownable.sol";

contract CheckpointContract is Ownable, ERC721BasicTokenContract {
    using SafeMath for uint256;
    
    struct Version {
        string hash;
        string description;
    }
    
    struct DocumentReference {
        uint256 documentId;
        uint256 versionId;
        uint256 createdAt;
    }
    
    /// @dev This will be used as unique auto incremented documentId 
    /// @dev mapping(documentId => Version[])
    /// @dev mapping(referenceId => DocumentReference)
    uint256 docRefCounter = 0; 
    mapping(uint256 => Version[]) versionOf; 
    mapping(bytes32 => DocumentReference) documentReference; 
    
    event DocumentSaved (
        bytes32 indexed referenceId,
        uint256 indexed documentId,
        uint256 indexed versionId,
        string hash
    );

    constructor(string _name, string _symbol) ERC721BasicTokenContract(_name, _symbol) public {
            
    }
    /*
    /// @dev   To save documnet in both create and update
    */
    function _save(uint256 documentId, string hash, string description) internal returns(bytes32) {
        require(!_emptyString(hash));
        require(!_hashExists(hash)); 
        /// @dev TODO: Audit this behavior 
        /// @dev throw error if hash already exists
        
        Version memory version = Version(hash, description);
        Version[] storage versions = versionOf[documentId];
        uint256 versionsLength = versions.push(version);
        uint256 versionId = versionsLength - 1;
        versionOf[documentId] = versions;

    /// @dev This will need to be upgraded for SSZ support
    /// @dev TODO: native encoding options, better hashing algo
    /// @dev add header content support for AS2
    /// @dev Convert hash of document into solidty-compatible bytes32 hash. This will be used as a transactionId (referenceId) for the document.
       
        bytes32 referenceId = keccak256(abi.encodePacked(hash)); 
        DocumentReference memory reference = DocumentReference(documentId, versionId, now);
        documentReference[referenceId] = reference;
        emit DocumentSaved(referenceId, documentId, versionId, hash);
        
        return referenceId;
    }

    /*
    /// @dev TODO: Audit, exploits?
    /// @dev   Double check hash does not already exists. 
    */
    function _hashExists(string hash) internal returns(bool) {
        bytes32 referenceId = keccak256(abi.encodePacked(hash));
        DocumentReference storage targetDocumentReference = documentReference[referenceId];
        return targetDocumentReference.createdAt != 0;
    }
    
    /*
        @dev TODO: Audit
        @dev Check given referenceId in query methods exists.
        @dev Just to check document track exists or not.
    */
    function _isReferenceExists(bytes32 referenceId) internal returns (bool) {
        DocumentReference storage targetDocumentReference = documentReference[referenceId];
        return targetDocumentReference.createdAt != 0;
    }
    
    function _emptyString(string input) internal returns(bool) {
        bytes memory tempEmptyStringTest = bytes(input); // Uses memory
        return tempEmptyStringTest.length == 0;
    }
    
    /*
        Get version details(hash, description) by referenceId of that version.
    */
    function _getByReferenceId(bytes32 referenceId) internal view returns(Version) {
        require(_isReferenceExists(referenceId));
        
        DocumentReference storage targetDocumentReference = documentReference[referenceId];
        Version[] storage versions = versionOf[targetDocumentReference.documentId];
        Version storage targetVersion = versions[targetDocumentReference.versionId];
        
        return targetVersion;
    }
    
    /*
        @dev Create a track of new document and return referenceId which can be used to check track of that document.
    */
    function createDocument(string hash, string description) external onlyOwner returns(bytes32) {
        bytes32 referenceId = _save(docRefCounter, hash, description);
        _mint(msg.sender, docRefCounter);
        docRefCounter = docRefCounter + 1;

        return referenceId;
    }

    /*
       @dev Accept referenceId of any previous track of a document and save the new version of that document using given data.
    */
    function updateDocument(bytes32 referenceId, string hash, string description) external onlyOwner returns(bytes32) {
        uint256 documentId = documentReference[referenceId].documentId;
        return _save(documentId, hash, description);
    }
    
    /*
      @dev  Accept a hash of any version of a document and return a list of hashes containing all versions hashes of that document.
    */
    function getAllByHash(string hash) external view returns(string[]) {
        require(_hashExists(hash));
        
        //Convert hash of document into solidty-compatible bytes32 hash. This will be used as a transactionId (referenceId) for the document.
        bytes32 referenceId =  keccak256(abi.encodePacked(hash));
        
        return getAllByReferenceId(referenceId);
    }
    
    /*
        @dev TODO: Audit
     @dev   Accept a referenceId of any version of a document and return hash of that version.
     @dev   * referenceId get in response of create/update document.
    */
    function getHashByReferenceId(bytes32 referenceId) external view returns(string) {
        return _getByReferenceId(referenceId).hash;
    }
    
    /*
    @dev TODO: Audit
     @dev   Accept a referenceId of any version of a document and return hash and description of that version. 
    @dev    * referenceId get in response of create/update document.
    */
    function getByReferenceId(bytes32 referenceId) external view returns(string, string) {
        require(_isReferenceExists(referenceId));
        
        Version memory targetVersion = _getByReferenceId(referenceId);
        
        return (targetVersion.hash, targetVersion.description);
    }
    
    /*
    @dev    Double check hash does not already exists for error handling.
    */
    
    function hashExists(string hash) external view returns(bool) {
        return _hashExists(hash);
    }
    
    /*
    @dev    Check given referenceId in query methods exists.
    @dev    Just to check document track exists or not.
    */
    function isReferenceExists(bytes32 referenceId) external returns (bool) {
        return _isReferenceExists(referenceId);
    }
    
    /*
    @dev    TODO: Audit
   @dev     Accept a referenceId of any version of a document and return a list of hashes containing all versions hashes of that document.
   @dev     * referenceId get in response of create/update document.
    */
    function getAllByReferenceId(bytes32 referenceId) public view returns(string[]) {
        require(_isReferenceExists(referenceId));
        
        DocumentReference storage targetDocumentReference = documentReference[referenceId];
        Version[] storage versions = versionOf[targetDocumentReference.documentId];
        string[] memory hashList = new string[](versions.length);
        for(uint256 i = 0; i < versions.length; i++) {
            hashList[i] = versions[i].hash;
        }
        
        return hashList;
    }
    
}