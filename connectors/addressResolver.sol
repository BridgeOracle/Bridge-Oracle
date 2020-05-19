pragma solidity ^0.5.9;

contract OracleAddrResolver {

    mapping(string => address) public oracleType;
    
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
    }
    
    function changeOwner(address newowner) onlyOwner public{
        owner = newowner;
    }
    
    function getAddress(string memory _oracleType) public returns (address oaddr){
        return oracleType[_oracleType];
    }
    
    function addOracleType(string memory oracleName, address oracleAddress) onlyOwner public {
        oracleType[oracleName] = oracleAddress;
    }

    function removeOracleType(string memory oracleName) onlyOwner public {
        delete oracleType[oracleName];
    }
    
}
