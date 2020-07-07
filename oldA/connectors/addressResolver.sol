pragma solidity ^0.5.8;

contract OracleAddrResolver {

    address public addr;
    
    address owner;
    
    constructor() internal{
        owner = msg.sender;
    }
    
    function changeOwner(address newowner) public{
        require(owner == msg.sender);
        owner = newowner;
    }
    
    function getAddress() public returns (address oaddr){
        return addr;
    }
    
    function setAddr(address newaddr) public{
        require(owner == msg.sender);
        addr = newaddr;
    }
    
}