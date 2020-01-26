pragma solidity ^0.5.8;

contract oracleI {
	address public cbAddress;

	function query(string calldata _datasource) external payable returns(bytes32 _id);
}


contract OracleAddrResolverI {
	function getAddress() public returns(address _address);
}

// oracleAddressResolver origin address TTuafMyqTXYpBoqD353FmhdosnGQMvJpv4

contract oracle {

	OracleAddrResolverI OAR;
	oracleI oracle;

	string internal oracle_network_name;
	uint8 internal networkID_auto = 0;

	modifier oracleAPI {
		if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0)) {
			oracle_setNetwork();
		}
		if(address(oracle) != OAR.getAddress()) {
			oracle = oracleI(OAR.getAddress());
		}
    _;
	}


	function oracle_query(string memory _datasource, string memory _arg) public payable oracleAPI returns(bytes32 _id) {
		return oracle.query.value(5)(_datasource, _arg);
	}

	function oracle_query(uint _timestamp, string memory _datasource, string memory _arg) public payable oracleAPI returns(bytes32 _id) {
		return oracle.query.value(5)(_timestamp, _datasource, _arg);
	}


	function oracle_setNetwork(uint8 _networkID) internal returns (bool _networkSet) {
      _networkID;
      return oracle_setNetwork();
    }

    function oracle_setNetworkName(string memory _network_name) internal {
        oracle_network_name = _network_name;
    }

    function oracle_setNetwork() internal returns (bool _networkSet) {
    	if (getCodeSize(0xC4c2ae73F8D30c696313530D43D45F071Ad0BB89) > 0) {
            OAR = OracleAddrResolverI(0xC4c2ae73F8D30c696313530D43D45F071Ad0BB89);
            oracle_setNetworkName("trx_shasta-test");
            return true;
        }
        return false;
    }


	function getCodeSize(address _addr) view internal returns(uint _size) {
		assembly {
			_size := extcodesize(_addr)
		}
	}


	function __callback(bytes32 _myid, string memory _result) public {

	}
}