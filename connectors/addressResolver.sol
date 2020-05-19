pragma solidity ^0.5.9;

contract OracleAddrResolver {

    mapping(string => address) public Oracle_type;
    
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function changeOwner(address newowner) public{
        require(owner == msg.sender);
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
