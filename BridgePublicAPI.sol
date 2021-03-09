pragma solidity ^0.5.9;

interface ITRC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract oracleI {
    address public cbAddress;
    function query(uint _timestamp, string calldata _datasource, string calldata _arg) external payable returns(bytes32 _id);
    function query_withFeeLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _feeLimit) external payable returns(bytes32 _id);
    function query2(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) public payable returns(bytes32 _id);
    function query2_withFeeLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _feeLimit) external payable returns(bytes32 _id);
    function queryN(uint _timestamp, string memory _datasource, bytes memory _argN) public payable returns(bytes32 _id);
    function queryN_withFeeLimit(uint _timestamp, string calldata _datasource, bytes calldata _argN, uint _gasLimit) external payable returns(bytes32 _id);
    function getPrice(string memory _datasource) public returns(uint256 TRXbasedPrice, uint256 discountPrice);
    function getPrice(string memory _datasource, uint _feeLimit) public returns(uint256 TRXbasedPrice, uint256 discountPrice);
    function getTokenStatus() external view returns(bool _status);
    function getRelativeDecimal() external returns(uint256 _dec);
    function getTokenPrice() public returns(uint256 _price);
}


/*


Begin solidity-cborutils

https://github.com/smartcontractkit/solidity-cborutils

MIT License

Copyright (c) 2018 SmartContract ChainLink, Ltd.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


*/

library Buffer {

    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory _buf, uint _capacity) internal pure {
        uint capacity = _capacity;
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        _buf.capacity = capacity; // Allocate space for the buffer data
        assembly {
            let ptr := mload(0x40)
            mstore(_buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory _buf, uint _capacity) private pure {
        bytes memory oldbuf = _buf.buf;
        init(_buf, _capacity);
        append(_buf, oldbuf);
    }

    function max(uint _a, uint _b) private pure returns (uint _max) {
        if (_a > _b) {
            return _a;
        }
        return _b;
    }

 /**
      * @dev Appends a byte array to the end of the buffer. Resizes if doing so
      *      would exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return The original buffer.
      *
      */
    function append(buffer memory _buf, bytes memory _data) internal pure returns (buffer memory _buffer) {
        if (_data.length + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _data.length) * 2);
        }
        uint dest;
        uint src;
        uint len = _data.length;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            dest := add(add(bufptr, buflen), 32) // Start address = buffer address + buffer length + sizeof(buffer length)
            mstore(bufptr, add(buflen, mload(_data))) // Update buffer length
            src := add(_data, 32)
        }
        for(; len >= 32; len -= 32) { // Copy word-length chunks while possible
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        uint mask = 256 ** (32 - len) - 1; // Copy remaining bytes
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
        return _buf;
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return The original buffer.
      *
      */
function append(buffer memory _buf, uint8 _data) internal pure {
        if (_buf.buf.length + 1 > _buf.capacity) {
            resize(_buf, _buf.capacity * 2);
        }
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), 32) // Address = buffer address + buffer length + sizeof(buffer length)
            mstore8(dest, _data)
            mstore(bufptr, add(buflen, 1)) // Update buffer length
        }
    }
    /**
      *
      * @dev Appends a byte to the end of the buffer. Resizes if doing so would
      * exceed the capacity of the buffer.
      * @param _buf The buffer to append to.
      * @param _data The data to append.
      * @return The original buffer.
      *
      */
    function appendInt(buffer memory _buf, uint _data, uint _len) internal pure returns (buffer memory _buffer) {
        if (_len + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _len) * 2);
        }
        uint mask = 256 ** _len - 1;
        assembly {
            let bufptr := mload(_buf) // Memory address of the buffer data
            let buflen := mload(bufptr) // Length of existing buffer data
            let dest := add(add(bufptr, buflen), _len) // Address = buffer address + buffer length + sizeof(buffer length) + len
            mstore(dest, or(and(mload(dest), not(mask)), _data))
            mstore(bufptr, add(buflen, _len)) // Update buffer length
        }
        return _buf;
    }
}

library CBOR {

    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory _buf, uint8 _major, uint _value) private pure {
        if (_value <= 23) {
            _buf.append(uint8((_major << 5) | _value));
        } else if (_value <= 0xFF) {
            _buf.append(uint8((_major << 5) | 24));
            _buf.appendInt(_value, 1);
        } else if (_value <= 0xFFFF) {
            _buf.append(uint8((_major << 5) | 25));
            _buf.appendInt(_value, 2);
        } else if (_value <= 0xFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 26));
            _buf.appendInt(_value, 4);
        } else if (_value <= 0xFFFFFFFFFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 27));
            _buf.appendInt(_value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory _buf, uint8 _major) private pure {
        _buf.append(uint8((_major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory _buf, uint _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_INT, _value);
    }

    function encodeInt(Buffer.buffer memory _buf, int _value) internal pure {
        if (_value >= 0) {
            encodeType(_buf, MAJOR_TYPE_INT, uint(_value));
        } else {
            encodeType(_buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - _value));
        }
    }

    function encodeBytes(Buffer.buffer memory _buf, bytes memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_BYTES, _value.length);
        _buf.append(_value);
    }

    function encodeString(Buffer.buffer memory _buf, string memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_STRING, bytes(_value).length);
        _buf.append(bytes(_value));
    }

    function startArray(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

/*

End solidity-cborutils

*/

contract OracleAddrResolverI {
    function getAddress(string memory ot) public returns(address _address);
    function getTokenAddress() public returns(address oaddr);
}

contract BridgePublicAPI {

    using CBOR for Buffer.buffer;
    
    OracleAddrResolverI OAR;
    oracleI oracle;

    string internal oracle_network_name;

    uint8 internal networkID_auto = 0;

    modifier oracleAPI {
        if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0)) {
            oracle_setNetwork();
        }
        if(address(oracle) != OAR.getAddress("public")) {
            oracle = oracleI(OAR.getAddress("public"));
        }
        _;
    }

    function payment1(uint256 timeout, string memory _datasource, string memory _arg, uint256 _feelimit) internal returns(bytes32 _id) {
        uint256 tokenPrice = oracle.getTokenPrice();
        address tokenAddress = OAR.getTokenAddress();
        if(_feelimit > 0) {
            (uint256 TRXbasedPrice, uint256 discountPrice) = oracle.getPrice(_datasource, _feelimit);
            uint256 tokenBasedPrice = (discountPrice * tokenPrice)/10 ** oracle.getRelativeDecimal();
            if (TRXbasedPrice > 1000 trx) {
                return 0; // Unexpectedly high price
            }
            if(oracle.getTokenStatus() && ITRC20(tokenAddress).balanceOf(address(this)) >= tokenBasedPrice){
                if (ITRC20(tokenAddress).allowance(address(this), address(oracle)) >= tokenBasedPrice) {
                    return oracle.query_withFeeLimit.value(0)(timeout, _datasource, _arg, _feelimit);
                } else {
                    require(ITRC20(tokenAddress).approve(OAR.getAddress("public"), uint(-1)));
                    return oracle.query_withFeeLimit.value(0)(timeout, _datasource, _arg, _feelimit);
                }
            }
            else {
                return oracle.query_withFeeLimit.value(TRXbasedPrice)(timeout,_datasource, _arg, _feelimit);
            }

        }else {
            (uint256 TRXbasedPrice, uint256 discountPrice) = oracle.getPrice(_datasource);
            uint256 tokenBasedPrice = (discountPrice * tokenPrice)/10 ** oracle.getRelativeDecimal();
            if (TRXbasedPrice > 1000 trx) {
                return 0; // Unexpectedly high price
            }
            if(oracle.getTokenStatus() && ITRC20(tokenAddress).balanceOf(address(this)) >= tokenBasedPrice){
                if (ITRC20(tokenAddress).allowance(address(this), address(oracle)) >= tokenBasedPrice) {
                    return oracle.query.value(0)(timeout, _datasource, _arg);
                } else {
                    require(ITRC20(tokenAddress).approve(OAR.getAddress("public"), uint(-1)));
                    return oracle.query.value(0)(timeout, _datasource, _arg);
                }
            }
            else {
                return oracle.query.value(TRXbasedPrice)(timeout,_datasource, _arg);
            }
        }
    }

     function payment2(uint256 timeout, string memory _datasource, string memory _arg1, string memory _arg2, uint256 _feelimit) internal returns(bytes32 _id) {
        uint256 tokenPrice = oracle.getTokenPrice();
        address tokenAddress = OAR.getTokenAddress();
        if(_feelimit > 0) {
            (uint256 TRXbasedPrice, uint256 discountPrice) = oracle.getPrice(_datasource, _feelimit);
            uint256 tokenBasedPrice = (discountPrice * tokenPrice)/10 ** oracle.getRelativeDecimal();
            if (TRXbasedPrice > 1000 trx) {
                return 0; // Unexpectedly high price
            }
            if(oracle.getTokenStatus() && ITRC20(tokenAddress).balanceOf(address(this)) >= tokenBasedPrice){
                if (ITRC20(tokenAddress).allowance(address(this), address(oracle)) >= tokenBasedPrice) {
                    return oracle.query2_withFeeLimit.value(0)(timeout, _datasource, _arg1, _arg2, _feelimit);
                } else {
                    require(ITRC20(tokenAddress).approve(OAR.getAddress("public"), uint(-1)));
                    return oracle.query2_withFeeLimit.value(0)(timeout, _datasource, _arg1, _arg2, _feelimit);
                }
            }
            else {
                return oracle.query2_withFeeLimit.value(TRXbasedPrice)(timeout,_datasource, _arg1, _arg2, _feelimit);
            }

        }else {
            (uint256 TRXbasedPrice, uint256 discountPrice) = oracle.getPrice(_datasource);
            uint256 tokenBasedPrice = (discountPrice * tokenPrice)/10 ** oracle.getRelativeDecimal();
            if (TRXbasedPrice > 1000 trx) {
                return 0; // Unexpectedly high price
            }
            if(oracle.getTokenStatus() && ITRC20(tokenAddress).balanceOf(address(this)) >= tokenBasedPrice){
                if (ITRC20(tokenAddress).allowance(address(this), address(oracle)) >= tokenBasedPrice) {
                    return oracle.query2.value(0)(timeout, _datasource, _arg1, _arg2);
                } else {
                    require(ITRC20(tokenAddress).approve(OAR.getAddress("public"), uint(-1)));
                    return oracle.query2.value(0)(timeout, _datasource, _arg1, _arg2);
                }
            }
            else {
                return oracle.query2.value(TRXbasedPrice)(timeout,_datasource, _arg1, _arg2);
            }
        }
    }

    function paymentN(uint256 timeout, string memory _datasource, bytes memory _args, uint256 _feelimit) internal returns(bytes32 _id) {
        uint256 tokenPrice = oracle.getTokenPrice();
        address tokenAddress = OAR.getTokenAddress();
        if(_feelimit > 0) {
            (uint256 TRXbasedPrice, uint256 discountPrice) = oracle.getPrice(_datasource, _feelimit);
            uint256 tokenBasedPrice = (discountPrice * tokenPrice)/10 ** oracle.getRelativeDecimal();
            if (TRXbasedPrice > 1000 trx) {
                return 0; // Unexpectedly high price
            }
            if(oracle.getTokenStatus() && ITRC20(tokenAddress).balanceOf(address(this)) >= tokenBasedPrice){
                if (ITRC20(tokenAddress).allowance(address(this), address(oracle)) >= tokenBasedPrice) {
                    return oracle.queryN_withFeeLimit.value(0)(timeout, _datasource, _args, _feelimit);
                } else {
                    require(ITRC20(tokenAddress).approve(OAR.getAddress("public"), uint(-1)));
                    return oracle.queryN_withFeeLimit.value(0)(timeout, _datasource, _args, _feelimit);
                }
            }
            else {
                return oracle.queryN_withFeeLimit.value(TRXbasedPrice)(timeout,_datasource, _args, _feelimit);
            }

        }else {
            (uint256 TRXbasedPrice, uint256 discountPrice) = oracle.getPrice(_datasource);
            uint256 tokenBasedPrice = (discountPrice * tokenPrice)/10 ** oracle.getRelativeDecimal();
            if (TRXbasedPrice > 1000 trx) {
                return 0; // Unexpectedly high price
            }
            if(oracle.getTokenStatus() && ITRC20(tokenAddress).balanceOf(address(this)) >= tokenBasedPrice){
                if (ITRC20(tokenAddress).allowance(address(this), address(oracle)) >= tokenBasedPrice) {
                    return oracle.queryN.value(0)(timeout, _datasource, _args);
                } else {
                    require(ITRC20(tokenAddress).approve(OAR.getAddress("public"), uint(-1)));
                    return oracle.queryN.value(TRXbasedPrice)(timeout,_datasource, _args);
                }
            }
            else {
                return oracle.queryN.value(TRXbasedPrice)(timeout,_datasource, _args);
            }
        }
    }

    function bridge_query(string memory _datasource, string memory _arg) internal oracleAPI returns(bytes32 _id) {
        return payment1(0, _datasource, _arg, 0);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string memory _arg) internal oracleAPI returns(bytes32 _id) {
        return payment1(_timestamp, _datasource, _arg, 0);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string memory _arg, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        return payment1(_timestamp, _datasource, _arg, _feeLimit);
    }

    function bridge_query(string memory _datasource, string memory _arg, uint _feeLimit) internal oracleAPI returns (bytes32 _id) {
        return payment1(0, _datasource, _arg, _feeLimit);
    }

    function bridge_query(string memory _datasource, string memory _arg1, string memory _arg2) internal oracleAPI returns(bytes32 _id) {
        return payment2(0, _datasource, _arg1, _arg2, 0);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) internal oracleAPI returns(bytes32 _id) {
        return payment2(_timestamp, _datasource, _arg1, _arg2, 0);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        return payment2(_timestamp, _datasource, _arg1, _arg2, _feeLimit);
    }

    function bridge_query(string memory _datasource, string memory _arg1, string memory _arg2, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
       return payment2(0, _datasource, _arg1, _arg2, _feeLimit);
    }

    function bridge_query(string memory _datasource, string[] memory _argN) internal oracleAPI returns(bytes32 _id) {
        bytes memory args = stra2cbor(_argN);
        return paymentN(0, _datasource, args, 0);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string[] memory _argN) internal oracleAPI returns(bytes32 _id) {
        bytes memory args = stra2cbor(_argN);
        return paymentN(_timestamp, _datasource, args, 0);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string[] memory _argN, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes memory args = stra2cbor(_argN);
        return paymentN(_timestamp, _datasource, args, _feeLimit);
    }

    function bridge_query(string memory _datasource, string[] memory _argN, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes memory args = stra2cbor(_argN);
        return paymentN(0, _datasource, args, _feeLimit);
    }

    function bridge_query(string memory _datasource, bytes[] memory _argN) internal oracleAPI returns(bytes32 _id) {
        bytes memory args = ba2cbor(_argN);
        return paymentN(0, _datasource, args, 0);
    }

    function bridge_query(uint _timestamp, string memory _datasource, bytes[] memory _argN) internal oracleAPI returns(bytes32 _id) {
        bytes memory args = ba2cbor(_argN);
        return paymentN(_timestamp, _datasource, args, 0);
    }

    function bridge_query(uint _timestamp, string memory _datasource, bytes[] memory _argN, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes memory args = ba2cbor(_argN);
        return paymentN(_timestamp, _datasource, args, _feeLimit);
    }

    function bridge_query(string memory _datasource, bytes[] memory _argN, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes memory args = ba2cbor(_argN);
        return paymentN(0, _datasource, args, _feeLimit);
    }

    function bridge_query(string memory _datasource, string[1] memory _args) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return bridge_query(_datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string[1] memory _args) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return bridge_query(_timestamp, _datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string[1] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return bridge_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, string[1] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return bridge_query(_datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, string[2] memory _args) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return bridge_query(_datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string[2] memory _args) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return bridge_query(_timestamp, _datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string[2] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return bridge_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, string[2] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return bridge_query(_datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, string[3] memory _args) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return bridge_query(_datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string[3] memory _args) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return bridge_query(_timestamp, _datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string[3] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return bridge_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, string[3] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return bridge_query(_datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, string[4] memory _args) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return bridge_query(_datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string[4] memory _args) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return bridge_query(_timestamp, _datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string[4] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return bridge_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, string[4] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return bridge_query(_datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, string[5] memory _args) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return bridge_query(_datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string[5] memory _args) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return bridge_query(_timestamp, _datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, string[5] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[2] = _args[2];
        dynargs[1] = _args[1];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return bridge_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, string[5] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return bridge_query(_datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, bytes[1] memory _args) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return bridge_query(_datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, bytes[1] memory _args) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return bridge_query(_timestamp, _datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, bytes[1] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return bridge_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, bytes[1] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return bridge_query(_datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, bytes[2] memory _args) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return bridge_query(_datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, bytes[2] memory _args) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return bridge_query(_timestamp, _datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, bytes[2] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return bridge_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, bytes[2] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return bridge_query(_datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, bytes[3] memory _args) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return bridge_query(_datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, bytes[3] memory _args) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return bridge_query(_timestamp, _datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, bytes[3] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return bridge_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, bytes[3] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return bridge_query(_datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, bytes[4] memory _args) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return bridge_query(_datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, bytes[4] memory _args) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return bridge_query(_timestamp, _datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, bytes[4] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return bridge_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, bytes[4] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return bridge_query(_datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, bytes[5] memory _args) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return bridge_query(_datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, bytes[5] memory _args) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return bridge_query(_timestamp, _datasource, dynargs);
    }

    function bridge_query(uint _timestamp, string memory _datasource, bytes[5] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[2] = _args[2];
        dynargs[1] = _args[1];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return bridge_query(_timestamp, _datasource, dynargs, _feeLimit);
    }

    function bridge_query(string memory _datasource, bytes[5] memory _args, uint _feeLimit) internal oracleAPI returns(bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return bridge_query(_datasource, dynargs, _feeLimit);
    }

    function oracle_getPrice(string memory _datasource) internal oracleAPI returns(uint256 TRXbasedPrice, uint256 discountPrice) {
        return oracle.getPrice(_datasource);
    }

    function oracle_getPrice(string memory _datasource, uint _feeLimit) internal oracleAPI returns(uint256 TRXbasedPrice, uint256 discountPrice) {
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
        if (getCodeSize(0x6457FBbf3ae193aBaC9b47B0809Ff1aF5236CD88) > 0) {
            OAR = OracleAddrResolverI(0x6457FBbf3ae193aBaC9b47B0809Ff1aF5236CD88);
            oracle_setNetworkName("trx_mainnet");
            return true;
        }else if (getCodeSize(0x292e33d054903Bf949b779A7A11ab799006cc7AC) > 0) {
            OAR = OracleAddrResolverI(0x292e33d054903Bf949b779A7A11ab799006cc7AC);
            oracle_setNetworkName("trx_shasta");
            return true;
        }else if (getCodeSize(0x25069835b2E21df48552899a5cC61c840d6D0C1F) > 0) {
            OAR = OracleAddrResolverI(0x25069835b2E21df48552899a5cC61c840d6D0C1F);
            oracle_setNetworkName("trx_nile");
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
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeString(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] memory _arr) internal pure returns(bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeBytes(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function safeMemoryCleaner() internal pure {
        assembly {
            let fmem := mload(0x40)
            codecopy(fmem, codesize, sub(msize, fmem))
        }
    }
}