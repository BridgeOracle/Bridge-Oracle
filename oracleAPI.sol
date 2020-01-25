pragma solidity ^0.5.8;

contract oracleI {
	address public cbAddress;

	function say_hi_from_connector(string memory name) public returns(string memory a);
}


contract OracleAddrResolverI {
	function getAddress() public returns(address _address);
}

// resolver contract
// original contract address : TNrcqfTa6WwryKPChfqczt523oMa7bArv9
// converted address : 0x8d5a9f578Ce5793e4Ad29999d477eF67881f0320
// end

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
    	if (getCodeSize(0xC4c2ae73F8D30c696313530D43D45F071Ad0BB89) > 0) {
            OAR = OracleAddrResolverI(0xC4c2ae73F8D30c696313530D43D45F071Ad0BB89);
            oracle_setNetworkName("trx_shasta-test");
            return true;
        }
    }


	function getCodeSize(address _addr) view internal returns(uint _size) {
		assembly {
			_size := extcodesize(_addr)
		}
	}

	function test(string memory s) public oracleAPI {
		oracle.say_hi_from_connector(s);
	}
}