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
    
    function getAddress() public returns (address oaddr){
        return addr;
    }
    
    function setAddr(address newaddr) public {
        require(owner == msg.sender);
        addr = newaddr;
    }
    
}
