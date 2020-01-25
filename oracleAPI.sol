pragma solidity ^0.5.8;

contract OracleAddrResolverI {
	function getAddress() public returns(address _address);
}
//resolver

//TBJuBAd36MWYyx2kugJ3AxS2vXuWZHxr7E deployed contract resolver
//TA5ZdL7Bn2XsWrQmu3uBjzWrxaXMzCoSXv main contract



contract oracle {

	OracleAddrResolverI OAR;
	

	string public oracle_network_name;
	uint8 internal networkID_auto = 0;

	modifier oracleAPI {
		if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0)) {
			oracle_setNetwork();
		}
		
    _;
	}


	function oracle_query(string memory _datasource, string memory _arg) oracleAPI internal returns(bytes memory _id) {
		// calc Price Here
	}


	function oracle_setNetwork(uint8 _networkID) internal returns (bool _networkSet) {
      _networkID;
      return oracle_setNetwork();
    }

    function oracle_setNetworkName(string memory _network_name) internal {
        oracle_network_name = _network_name;
    }

    function oracle_setNetwork() internal returns (bool _networkSet) {
    	if (getCodeSize(0x0eB1909A04848D61EdA5115F79816455fAEeB95E) > 0) { //mainnet
            OAR = OracleAddrResolverI(0x0eB1909A04848D61EdA5115F79816455fAEeB95E);
            oracle_setNetworkName("trx_shasta-test");
            return true;
        }
    }


	function getCodeSize(address _addr) view internal returns(uint _size) {
		assembly {
			_size := extcodesize(_addr)
		}
	}

}