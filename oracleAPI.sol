pragma solidity ^0.5.8;

contract oracleI {
	address public cbAddress;

	function query(uint _timestamp, string calldata _datasource, string calldata _arg) external payable returns(bytes32 _id);
	function query_withFeeLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _feeLimit) external payable returns(bytes32 _id);
	function query2(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) public payable returns(bytes32 _id);
	function query2_withFeeLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _feeLimit) external payable returns(bytes32 _id);
    function queryN(uint _timestamp, string memory _datasource, bytes memory _argN) public payable returns(bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string calldata _datasource, bytes calldata _argN, uint _gasLimit) external payable returns(bytes32 _id);
	function setProofType(byte _proofType) external;
	function getPrice(string memory _datasource) public returns(uint _dsprice);
	function getPrice(string memory _datasource, uint _feeLimit) public returns(uint _dsprice);
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
		uint256 price = oracle.getPrice(_datasource);
        uint256 feeLimit = 1000 TRX;
        if (price > 1000 TRX + feeLimit) {
            return 0; // Unexpectedly high price
        }
        return oracle.query.value(price)(0, _datasource, _arg);
	}

	function oracle_query(uint _timestamp, string memory _datasource, string memory _arg) public oracleAPI returns(bytes32 _id) {
		uint256 price = oracle.getPrice(_datasource);
        uint256 feeLimit = 1000 TRX;
        if (price > 1000 TRX + feeLimit) {
            return 0; // Unexpectedly high price
        }
        return oracle.query.value(price)(_timestamp, _datasource, _arg);
	}

	function oracle_query(uint _timestamp, string memory _datasource, string memory _arg, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
		uint256 price = oracle.getPrice(_datasource, _feeLimit);
        if (price > 1000 TRX + _feeLimit) {
            return 0; // Unexpectedly high price
        }
        return oracle.query_withFeeLimit.value(price)(_timestamp, _datasource, _arg, _feeLimit);
	}

    function provable_query(string memory _datasource, string memory _arg, uint _feeLimit) provableAPI internal returns (bytes32 _id) {
        uint price = provable.getPrice(_datasource, _feeLimit);
        if (price > 1000 TRX + _feeLimit) {
           return 0; // Unexpectedly high price
        }
        return provable.query_withFeeLimit.value(price)(0, _datasource, _arg, _feeLimit);
    }

	function oracle_query(string memory _datasource, string memory _arg1, string memory _arg2) public oracleAPI returns(bytes32 _id) {
		uint256 price = oracle.getPrice(_datasource);
        uint256 feeLimit = 1000 TRX;
        if (price > 1000 TRX + feeLimit) {
            return 0; // Unexpectedly high price
        }
        return oracle.query2.value(price)(0, _datasource, _arg1, _arg2);
	}

    function oracle_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) public oracleAPI returns(bytes32 _id) {
		uint256 price = oracle.getPrice(_datasource);
        uint256 feeLimit = 1000 TRX;
        if (price > 1000 TRX + feeLimit) {
            return 0; // Unexpectedly high price
        }
        return oracle.query2.value(price)(_timestamp, _datasource, _arg1, _arg2);
	}

	function oracle_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
		uint256 price = oracle.getPrice(_datasource, _feeLimit);
        if (price > 1000 TRX + feeLimit) {
            return 0; // Unexpectedly high price
        }
        return oracle.query2_withFeeLimit.value(price)(_timestamp, _datasource, _arg1, _arg2, _feeLimit);
	}

	function oracle_query(string memory _datasource, string memory _arg1, string memory _arg2, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
		uint256 price = oracle.getPrice(_datasource, _feeLimit);
        if (price > 1000 TRX + feeLimit) {
            return 0; // Unexpectedly high price
        }
        return oracle.query2_withFeeLimit.value(price)(0, _datasource, _arg1, _arg2, _feeLimit);
	}

    function oracle_query(string memory _datasource, string[] memory _argN) public oracleAPI returns(bytes32 _id) {
        uint256 price = oracle.getPrice(_datasource);
        if(price > 1000 trx + feeLimit) {
            return 0;
        }
        bytes memory args = stra2cbor(_argN);
        return oracle.queryN.value(price)(0, _datasource, args);
    }

    function oracle_query(uint _timestamp, string memory _datasource, string[] memory _argN) public oracleAPI returns(bytes32 _id) {
        uint256 price = oracle.getPrice(_datasource);
        if(price > 1000 trx + feeLimit) {
            return 0;
        }
        bytes memory args = stra2cbor(_argN);
        return oracle.queryN.value(price)(_timestamp, _datasource, args);
    }
    
    function oracle_query(uint _timestamp, string memory _datasource, string[] memory _argN, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        uint256 price = oracle.getPrice(_datasource, _feeLimit);
        if(price > 1000 trx + feeLimit) {
            return 0;
        }
        bytes memory args = stra2cbor(_argN);
        return oracle.queryN_withGasLimit.value(price)(_timestamp, _datasource, args, _feeLimit);
    }

    function oracle_query(string memory _datasource, string[] memory _argN, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        uint256 price = oracle.getPrice(_datasource, _feeLimit);
        if(price > 1000 trx + feeLimit) {
            return 0;
        }
        bytes memory args = stra2cbor(_argN);
        return oracle.queryN_withGasLimit.value(price)(0, _datasource, args, _feeLimit);
    }

    function oracle_query(string memory _datasource, bytes[] memory _argN, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        uint256 price = oracle.getPrice(_datasource, _feeLimit);
        if(price > 1000 trx + feeLimit) {
            return 0;
        }
        bytes memory args = ba2cbor(_argN);
        return oracle.queryN_withGasLimit.value(price)(0, _datasource, args, _feeLimit);
    }

    function oracle_query(uint _timestamp, string memory _datasource, bytes[] memory _argN, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        uint256 price = oracle.getPrice(_datasource, _feeLimit);
        if(price > 1000 trx + feeLimit) {
            return 0;
        }
        bytes memory args = ba2cbor(_argN);
        return oracle.queryN_withGasLimit.value(price)(_timestamp, _datasource, args, _feeLimit);
    }

    function oracle_query(string memory _datasource, string[1] memory _args) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oracle_query(_datasource, dynargs);
    }

    function oracle_query(uint _timestamp, string memory _datasource, string[1] memory _args) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oracle_query(_timestamp, _datasource, dynargs);
    }

     function oracle_query(uint _timestamp, string memory _datasource, string[1] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oracle_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function oracle_query(string memory _datasource, string[1] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oracle_query(_datasource, dynargs, _feeLimit);
    }

    function oracle_query(string memory _datasource, string[2] memory _args) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oracle_query(_datasource, dynargs);
    }

    function oracle_query(uint _timestamp, string memory _datasource, string[2] memory _args) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oracle_query(_timestamp, _datasource, dynargs);
    }

    function oracle_query(string memory _datasource, string[2] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oracle_query(_timestamp, _datasource, dynargs, _feeLimit);
    }
    
    function oracle_query(string memory _datasource, string[2] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oracle_query(_datasource, dynargs, _feeLimit);
    }
    
    function oracle_query(string memory _datasource, string[3] memory _args) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oracle_query(_datasource, dynargs);
    }
    
    function oracle_query(uint _timestamp, string memory _datasource, string[3] memory _args) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oracle_query(_timestamp, _datasource, dynargs);
    }
    
    function oracle_query(uint _timestamp, string memory _datasource, string[3] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oracle_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function oracle_query(string memory _datasource, string[3] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oracle_query(_datasource, dynargs, _feeLimit);
    }

    function oracle_query(string memory _datasource, string[4] memory _args) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oracle_query(_datasource, dynargs);
    }

    function oracle_query(uint _timestamp, string memory _datasource, string[4] memory _args) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oracle_query(_timestamp, _datasource, dynargs);
    }

    function oracle_query(uint _timestamp, string memory _datasource, string[4] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oracle_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function oracle_query(string memory _datasource, string[4] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oracle_query(_datasource, dynargs, _feeLimit);
    }

    function oracle_query(string memory _datasource, string[5] memory _args) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oracle_query(_datasource, dynargs);
    }

    function oracle_query(uint _timestamp, string memory _datasource, string[5] memory _args) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oracle_query(_timestamp, _datasource, dynargs);
    }
    
    function oracle_query(uint _timestamp, string memory _datasource, string[5] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[2] = _args[2];
        dynargs[1] = _args[1];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oracle_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function oracle_query(uint _timestamp, string memory _datasource, string[5] memory _args) public oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oracle_query(_datasource, dynargs, _feeLimit);
    }

    function oracle_query(string memory _datasource, bytes[1] memory _args) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oracle_query(_datasource, dynargs);
    }

    function oracle_query(uint _timestamp, string memory _datasource, bytes[1] memory _args) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oracle_query(_timestamp, _datasource, dynargs);
    }

     function oracle_query(uint _timestamp, string memory _datasource, bytes[1] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oracle_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function oracle_query(string memory _datasource, bytes[1] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oracle_query(_datasource, dynargs, _feeLimit);
    }

    function oracle_query(string memory _datasource, bytes[2] memory _args) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oracle_query(_datasource, dynargs);
    }

    function oracle_query(uint _timestamp, string memory _datasource, bytes[2] memory _args) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oracle_query(_timestamp, _datasource, dynargs);
    }

    function oracle_query(string memory _datasource, bytes[2] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oracle_query(_timestamp, _datasource, dynargs, _feeLimit);
    }
    
    function oracle_query(string memory _datasource, bytes[2] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oracle_query(_datasource, dynargs, _feeLimit);
    }
    
    function oracle_query(string memory _datasource, bytes[3] memory _args) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oracle_query(_datasource, dynargs);
    }
    
    function oracle_query(uint _timestamp, string memory _datasource, bytes[3] memory _args) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oracle_query(_timestamp, _datasource, dynargs);
    }
    
    function oracle_query(uint _timestamp, string memory _datasource, bytes[3] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oracle_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function oracle_query(string memory _datasource, bytes[3] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oracle_query(_datasource, dynargs, _feeLimit);
    }

    function oracle_query(string memory _datasource, bytes[4] memory _args) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oracle_query(_datasource, dynargs);
    }

    function oracle_query(uint _timestamp, string memory _datasource, bytes[4] memory _args) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oracle_query(_timestamp, _datasource, dynargs);
    }

    function oracle_query(uint _timestamp, string memory _datasource, bytes[4] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oracle_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function oracle_query(string memory _datasource, bytes[4] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oracle_query(_datasource, dynargs, _feeLimit);
    }

    function oracle_query(string memory _datasource, bytes[5] memory _args) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oracle_query(_datasource, dynargs);
    }

    function oracle_query(uint _timestamp, string memory _datasource, bytes[5] memory _args) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oracle_query(_timestamp, _datasource, dynargs);
    }
    
    function oracle_query(uint _timestamp, string memory _datasource, bytes[5] memory _args, uint _feeLimit) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[2] = _args[2];
        dynargs[1] = _args[1];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oracle_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function oracle_query(uint _timestamp, string memory _datasource, bytes[5] memory _args) public oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oracle_query(_datasource, dynargs, _feeLimit);
    }

    
    
	function oracle_getPrice(string memory _datasource) internal oracleAPI returns(uint _queryPrice) {
		return oracle.getPrice(_datasource);
	}

	function oracle_getPrice(string memory _datasource, uint _feeLimit) internal oracleAPI returns(uint _queryPrice) {
		return oracle.getPrice(_datasource, _feeLimit);
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

    function oracle_cbAddress() internal oracleAPI returns(address _callbackAddress) {
        return oracle.cbAddress();
    }

	function strCompare(string memory _a, string memory _b) internal pure returns (int _returnCode) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) {
            minLength = b.length;
        }
        for (uint i = 0; i < minLength; i ++) {
            if (a[i] < b[i]) {
                return -1;
            } else if (a[i] > b[i]) {
                return 1;
            }
        }
        if (a.length < b.length) {
            return -1;
        } else if (a.length > b.length) {
            return 1;
        } else {
            return 0;
        }
    }

	function indexOf(string memory _haystack, string memory _needle) internal pure returns (int _returnCode) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length)) {
            return -1;
        } else if (h.length > (2 ** 128 - 1)) {
            return -1;
        } else {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i++) {
                if (h[i] == n[0]) {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) {
                        subindex++;
                    }
                    if (subindex == n.length) {
                        return int(i);
                    }
                }
            }
            return -1;
        }
    }

	function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }
	
	function safeParseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return safeParseInt(_a, 0);
    }

    function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal encountered in string!');
                decimals = true;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }
	
	function parseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return parseInt(_a, 0);
    }

    function parseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) {
                       break;
                   } else {
                       _b--;
                   }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

	function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function stra2cbor(string[] memory _arr) internal pure returns(bytes memory _cborEncoding) {
        safeMemoryCleaner();
    }

    function ba2cbor(bytes[] memory _arr) internal pure returns(bytes memory _cborEncoding) {
        safeMemoryCleaner();
    }
    
    function safeMemoryCleaner() internal pure {
        assembly {
            let fmem := mload(0x40)
            codecopy(fmem, codesize, sub(msize, fmem))
        }
    }
    
}