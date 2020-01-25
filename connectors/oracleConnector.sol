pragma solidity ^0.5.8;


contract Oracle {

	function say_hi_from_connector(string memory name) public returns(string memory a){
		return name;
	} 
}