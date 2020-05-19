    pragma solidity ^0.5.9;
    
    interface ITRC20 {
        function balanceOf(address who) external returns (uint);
        function transferFrom(address from, address to, uint256 value) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
    }

    contract Oracle {
        
        event Log1(address sender, bytes32 cid, uint timestamp, string _datasource, string _arg, uint feelimit);
        event Log2(address sender, bytes32 cid, uint timestamp, string _datasource, string _arg1, string _arg2, uint feelimit);
        event logN(address sender, bytes32 cid, uint timestamp, string _datasource, bytes args, uint feelimit);
        
        event Emit_OffchainPaymentFlag(address indexed idx_sender, address sender, bool indexed idx_flag, bool flag);
        
        address internal paymentFlagger;
        mapping (address => bool) public offchainPayment;

         bool public usingToken;

        function tokenPermission() public onlyAdmin {
            if(usingToken)
                usingToken = false;
            else
                usingToken = true;
        }


        uint256 private tokenPrice;

        function setTokenPrice(uint256 _price) public onlyAdmin {
            tokenPrice = _price;
            emit updatePrice(_price, now);
        }
        
        
        mapping(address => uint) internal reqc;
        mapping(address => byte) public cbAddresses;
        uint public basePrice;
        uint256 public maxBandWidthPrice; 
        uint256 public defaultFeeLimit;
        bytes32[] dsources;
        address private owner;
        mapping (bytes32 => uint) price_multiplier;
        
        constructor() public {
            owner = msg.sender;
        }
        
        function changeAdmin(address _newAdmin) external onlyAdmin {
            owner = _newAdmin;
        }
        
        function changePaymentFlagger(address _newFlagger) external onlyAdmin {
            paymentFlagger = _newFlagger;
        }
        
        function setOffchainPayment(address _addr, bool _flag) external {
            require(msg.sender == paymentFlagger);
            offchainPayment[_addr] = _flag;
            emit Emit_OffchainPaymentFlag(_addr, _addr, _flag, _flag);
        }
    
        modifier onlyAdmin() {
            require(owner == msg.sender);
            _;
        }
    
        function setMaxBandWidthPrice(uint256 new_maxBandWidthPrice) external onlyAdmin {
            maxBandWidthPrice = new_maxBandWidthPrice;
        }

        function setDefaultFeeLimit(uint256 new_defaultFeeLimit) external onlyAdmin {
            defaultFeeLimit = new_defaultFeeLimit;
        }
        
    
        function addCbAddress(address newCbAddress, byte addressType) public onlyAdmin{
            cbAddresses[newCbAddress] = addressType;
        }
    
        function removeCbAddress(address newCbAddress) external onlyAdmin {
            delete cbAddresses[newCbAddress];
        }
    
        function addDSource(string memory dsname, uint multiplier) public onlyAdmin
        {
            bytes32 dsname_hash = sha256(abi.encodePacked(dsname));
            dsources[dsources.length++] = dsname_hash;
            price_multiplier[dsname_hash] = multiplier;
        }
    
        function cbAddress() external view returns(address _cbAddress) {
            if(cbAddresses[tx.origin] != 0)
                _cbAddress = tx.origin;
        }
    
        function setBasePrice(uint new_baseprice) external onlyAdmin {
            basePrice = new_baseprice;
            for (uint i =0; i< dsources.length; i++) price[dsources[i]] = new_baseprice*price_multiplier[dsources[i]];
        }
        
        function getPrice(string memory _datasource) public view  returns(uint _dsprice) {
            return getPrice(_datasource, msg.sender);
        }
        
        function getPrice(string memory _datasource, uint _feeLimit) public view returns(uint _dsprice) {
            return getPrice(_datasource, _feeLimit, msg.sender);
        }
        
        function getPrice(string memory _datasource, address _addr) private view returns(uint _dsprice) {
            return getPrice(_datasource, defaultFeeLimit, _addr);
        }
        
        mapping (bytes32 => uint) price;
        
        function getPrice(string memory _datasource, uint _feeLimit, address _addr) private view returns(uint _dsprice) {
            if(offchainPayment[_addr]) {
                return 0;
            }
            require(_feeLimit <= defaultFeeLimit);
            _dsprice = price[sha256(abi.encodePacked(_datasource))];
            _dsprice += maxBandWidthPrice + _feeLimit;
            return _dsprice;
        }
    
        function costs(string memory datasource, uint feelimit) private returns(uint _price) {
            _price = getPrice(datasource, feelimit, msg.sender);
            address _owner = msg.sender;
            if (msg.value >= _price) {
                uint diff  = msg.value - _price;
                if (diff > 0) {
                    if (!msg.sender.send(diff)) {
                        revert();
                    }
                }
            } else revert();
        }
        
        function withdrawFunds(address payable _addr) external onlyAdmin {
            _addr.transfer(address(this).balance);
        }
    
        function query(string calldata _datasource, string calldata _arg) external payable returns(bytes32 _id) {
            //set feeLimit tron blockchain
            return query1(0, _datasource, _arg, defaultFeeLimit);
        }
        
        function query(uint _timestamp, string calldata _datasource, string calldata _arg) payable external returns(bytes32 _id) {
            return query1(_timestamp, _datasource, _arg, defaultFeeLimit);
        }
    
        function query_withFeeLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _feelimit) external payable returns(bytes32 _id) {
            return query1(_timestamp, _datasource, _arg, _feelimit);
        }
    
        function query2(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2) external payable returns(bytes32 _id) {
            return query2(_timestamp, _datasource, _arg1, _arg2, defaultFeeLimit);
        }
    
        function query2_withFeeLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _feeLimit) external payable returns(bytes32 _id) {
            return query2(_timestamp, _datasource, _arg1, _arg2, _feeLimit);
        }
    
        function queryN(string calldata _datasource, bytes calldata _args) external payable returns(bytes32 _id) {
            return queryN(0, _datasource, _args, defaultFeeLimit);
        }
    
        function queryN(uint _timestamp, string calldata _datasource, bytes calldata _args) external payable returns(bytes32 _id) {
            return queryN(_timestamp, _datasource, _args, defaultFeeLimit);
        }
    
        function query1(uint _timestamp, string memory _datasource, string memory _arg, uint _feeLimit) public payable returns(bytes32 _id) {
            costs(_datasource, _feeLimit);
            _id = sha256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
            reqc[msg.sender]++;
            emit Log1(msg.sender, _id, _timestamp, _datasource, _arg, _feeLimit);
            return _id;
        }
    
        function query2(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _feeLimit) public payable returns(bytes32 _id) {
            costs(_datasource, _feeLimit);
            _id = sha256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
            reqc[msg.sender]++;
            emit Log2(msg.sender, _id, _timestamp, _datasource, _arg1, _arg2, _feeLimit);
            return _id;
        }
    
        function queryN(uint _timestamp, string memory _datasource, bytes memory _args, uint _feelimit) public payable returns(bytes32 _id) {
            costs(_datasource, _feelimit);
            _id = sha256(abi.encodePacked(this, msg.sender, reqc[msg.sender]));
            reqc[msg.sender]++;
            emit logN(msg.sender, _id, _timestamp, _datasource, _args, _feelimit);
            return _id;
        }
    }