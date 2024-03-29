// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.6;

contract OracleAddrResolver {

    address public tokenAddress;

    mapping(bytes32 => address) public oracleType;
    
    address owner;

    string[] public oracles;
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address newowner) public onlyOwner {
        owner = newowner;
    }
    
    function getAddress(string memory _oracleType) public view returns (address oaddr){
        bytes32 __oracleType = sha256(abi.encodePacked(_oracleType));
        return oracleType[__oracleType];
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }
    
    function getTokenAddress() public view returns(address _tokenAddress) {
        return tokenAddress;
    }
    
    function addOracleType(string memory oracleName, address oracleAddress) public onlyOwner {
        bytes32 __oracleType = sha256(abi.encodePacked(oracleName));
        require(oracleType[__oracleType] == address(0));
        oracles.push(oracleName);
        oracleType[__oracleType] = oracleAddress;
    }

    function removeOracleType(string memory oracleName) public onlyOwner {
        bytes32 __oracleType = sha256(abi.encodePacked(oracleName));
        require(oracleType[__oracleType] != address(0));
        delete oracleType[__oracleType];
        uint len = oracles.length;
        for(uint i = 0; i < len; i++){
            if(sha256(abi.encodePacked(oracles[i])) == __oracleType) {
                oracles[i] = oracles[len - 1];
                delete oracles[len - 1];
                len--;
                break;
            }
        }
    }

    function oracleArrayLen() public view returns (uint256 arrayLen) {
        return oracles.length;
    }
    
}
