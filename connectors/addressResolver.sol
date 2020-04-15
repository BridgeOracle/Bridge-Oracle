pragma solidity ^0.5.9;

contract OracleAddrResolver {

    address public addr;
    
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
