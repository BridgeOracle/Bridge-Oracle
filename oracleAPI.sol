pragma solidity ^0.5.8;

contract oracleI {
	address public cbAddress;

	function query(uint _timestamp, string calldata _datasource, string calldata _arg) external payable returns(bytes32 _id);
	function query_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _gasLimit) external payable returns(bytes32 _id);
	function query2(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) public payable returns(bytes32 _id);
	function query2_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _gasLimit) external payable returns(bytes32 _id);
	function setProofType(byte _proofType) external;
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

	byte constant proofType_NONE = 0x00;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    byte constant proofType_Android = 0x40;
    byte constant proofType_TLSNotary = 0x10;

	modifier oracleAPI {
		if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0)) {
			oracle_setNetwork();
		}
		if(address(oracle) != OAR.getAddress()) {
			oracle = oracleI(OAR.getAddress());
		}
    _;
	}

	function oracle_setProof(byte _proofP) internal oracleAPI {
		return oracle.setProofType(_proofP);
	}


	function oracle_query(string memory _datasource, string memory _arg) public oracleAPI returns(bytes32 _id) {
		return oracle.query.value(5000000)(0, _datasource, _arg);
	}

	function oracle_query(uint _timestamp, string memory _datasource, string memory _arg) public oracleAPI returns(bytes32 _id) {
		return oracle.query.value(5000000)(_timestamp, _datasource, _arg);
	}

	function oracle_query(uint _timestamp, string memory _datasource, string memory _arg, uint _gasLimit) public oracleAPI returns(bytes32 _id) {
		return oracle.query_withGasLimit.value(5000000)(_timestamp, _datasource, _arg, _gasLimit);
	}

	function oracle_query(string memory _datasource, string memory _arg1, string memory _arg2) public oracleAPI returns(bytes32 _id) {
		return oracle.query2.value(5000000)(0, _datasource, _arg1, _arg2);
	}

	function oracle_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) public oracleAPI returns(bytes32 _id) {
		return oracle.query2_withGasLimit.value(5000000)(_timestamp, _datasource, _arg1, _arg2, _gasLimit);
	}

	function oracle_query(string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) public oracleAPI returns(bytes32 _id) {
		return oracle.query2_withGasLimit.value(5000000)(0, _datasource, _arg1, _arg2, _gasLimit);
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
       	if(getCodeSize(0x29c1063e89803FBD81c7A84740054A1F9dC0fc68) > 0) {
       		OAR = OracleAddrResolverI(0x29c1063e89803FBD81c7A84740054A1F9dC0fc68);
            oracle_setNetworkName("trx_nile_test");
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