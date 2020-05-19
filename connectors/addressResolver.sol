pragma solidity ^0.5.9;

contract OracleAddrResolver {

    mapping(string => address) public oracleType;
    
    address owner;

    string[] public oracles;
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address newowner) onlyOwner public{
        owner = newowner;
    }
    
    function getAddress(string memory _oracleType) public returns (address oaddr){
        return oracleType[_oracleType];
    }
    
    function addOracleType(string memory oracleName, address oracleAddress) onlyOwner public {
        require(oracleType[oracleName] == address(0));
        oracles.push(oracleName);
        oracleType[oracleName] = oracleAddress;
    }

    function removeOracleType(string memory oracleName) onlyOwner public {
        require(oracleType[oracleName] != address(0));
        delete oracleType[oracleName];
        uint len = oracles.length;
        for(uint i = 0; i < len; i++){
            if(oracles[i] == oracleName) {
                oracles[i] = oracles[oracles.length - 1];
                delete oracles[oracles.length - 1];
                oracles.length--;
                break;
            }
        }
    }

    function oracleArrayLen() public view returns (uint256 arrayLen) {
        return oracles.length;
    }
    
}
