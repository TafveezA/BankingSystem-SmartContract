// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./IERC20.sol";
//import "./SafeMath.sol";
//import "./Services.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract BankingSystem {
    AggregatorV3Interface public priceFeed;
    IERC20 public token1;

    IERC20 public token2;
    

    mapping(address => uint256) assetInUsd;
    mapping(address => uint256) assetInEur;

    // uint256 iRateOfBorrowing;
    // uint256 interestRateOfDepositing;

    constructor(address _token1, address _token2) {
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);

        priceFeed = AggregatorV3Interface(
            0x7d7356bF6Ee5CDeC22B216581E48eCC700D0497A
        );
    }
    // for goerli testnet
// 0x44390589104C9164407A0E0562a9DBe6C24A0E05


    struct totalAsset {
        uint256 totalAssetWithBank;
        uint256 totalAssetWithBranch;
        uint256 totalAssetWithClient;
    }
    mapping(uint256 => totalAsset) public totalAssets;

    struct Bank {
        address centralBank;
        address bank;
        uint256 bankId;
        string tokenSymbol;
        uint256 centralBankId;
        uint256 amount;
        bool status;
    }

    mapping(uint256 => Bank) public banks;
    

    function addBank(
        address _bankAddress,
        string memory _tokenSymbol,
        uint256 _centralBankId,
        uint256 _amount
    ) public  {
        require(
            (token1.getBankOwner() == msg.sender && _centralBankId == 0) ||
                (token2.getBankOwner() == msg.sender && _centralBankId == 1),
            "You are not fed or Ecb or Enter correct ID"
        );
        require(
            token1.balanceOf(msg.sender) >= _amount ||
                token2.balanceOf(msg.sender) >= _amount,
            "Not Enoungh Funds"
        );
        banks[_centralBankId] = Bank(
            msg.sender,
            _bankAddress,
            _centralBankId,
            _tokenSymbol,
            _centralBankId,
            _amount,
            true
        );
        idOfAddress[_bankAddress].bankId =_centralBankId;
        if (_centralBankId == 0) {
            _safeTransferFrom(token1, msg.sender, _bankAddress, _amount);
            totalAssets[_centralBankId].totalAssetWithBank = _amount;
        } else {
            _safeTransferFrom(token2, msg.sender, _bankAddress, _amount);
            totalAssets[_centralBankId].totalAssetWithBank = _amount;
        }

        return;
    }


    struct Id{
        uint bankId;
        uint256 branchId;
        uint256 clientId;
    }
    mapping(address=>Id) public idOfAddress;

    struct Branch {
        uint256 bankId;
        uint256 branchId;
        address branch;
        address bank;
        uint256 amount;
        string tokenSymbol;
    }
    mapping(uint256 => mapping(uint256 => Branch)) public branches;
    // mapping of bankId to branch Id to branches
    mapping(uint256 => uint256) public branchCount;

    //mapping of bankId to branchId

    function addBranch(
        uint256 _bankId,
        address _branchAddress,
        uint256 _amount,
        string memory _tokenSymbol
    ) public returns (uint256 branchId) {
        require(banks[_bankId].bank == msg.sender, "Access Denied");
        require(
            (token1.balanceOf(msg.sender) >= _amount && _bankId == 0) ||
                (token2.balanceOf(msg.sender) >= _amount && _bankId == 1),
            "Not Enoungh Funds"
        );
        require(
            token1.allowance(msg.sender, address(this)) >= _amount ||
                token2.allowance(msg.sender, address(this)) >= _amount,
            "Token Allowance is Low"
        );
        branches[_bankId][branchCount[_bankId]] = Branch(
            _bankId,
            branchCount[_bankId],
            _branchAddress,
            msg.sender,
            _amount,
            _tokenSymbol
        );
        idOfAddress[_branchAddress].bankId =_bankId;
        idOfAddress[_branchAddress].branchId = branchCount[_bankId];

        if (_bankId == 0) {
            _safeTransferFrom(token1, msg.sender, _branchAddress, _amount);
            totalAssets[_bankId].totalAssetWithBranch += _amount;
        } else {
            _safeTransferFrom(token2, msg.sender, _branchAddress, _amount);
            totalAssets[_bankId].totalAssetWithBranch += _amount;
        }

        branchCount[_bankId] += 1;
        return branchCount[_bankId];
    }

    struct Client {
        uint256 bankId;
        uint256 branchId;
        uint256 clientId;
        address client;
        uint256 amount;
        string tokenSymbol;
    }
    mapping(uint256 => mapping(uint256 => Client)) public clients;
    // mapping of bankId to clientId to Client
    mapping(uint256 => mapping(uint256 => uint256)) public clientCount;
    //mapping(address=>uint256) clientCount;

    //mapping of bankid,branchId to clientId

    function addClient(
        uint256 _bankId,
        uint256 _branchId,
        address _clientAddress,
        uint256 _amount,
        string memory _tokenSymbol
    ) public returns (uint256 clientId) {
        require(
            branches[_bankId][_branchId].branch == msg.sender,
            "Only Branch Can Add client"
        );
        require(
            (token1.balanceOf(msg.sender) >= _amount && _bankId == 0) ||
                (token2.balanceOf(msg.sender) >= _amount && _bankId == 1),
            "Not Enoungh Funds"
        );
        require(
            token1.allowance(msg.sender, address(this)) >= _amount ||
                token2.allowance(msg.sender, address(this)) >= _amount,
            "Token Allowance is Low"
        );
        clients[_bankId][clientCount[_bankId][_branchId]] = Client(
            _bankId,
            _branchId,
            clientCount[_bankId][_branchId],
            _clientAddress,
            _amount,
            _tokenSymbol
        );
         idOfAddress[ _clientAddress].bankId =_bankId;
        idOfAddress[ _clientAddress].branchId = _branchId;
         idOfAddress[ _clientAddress].clientId =  clientCount[_bankId][_branchId];
        

        if (_bankId == 0) {
            _safeTransferFrom(token1, msg.sender, _clientAddress, _amount);
            totalAssets[_bankId].totalAssetWithClient += _amount;
        } else {
            _safeTransferFrom(token2, msg.sender, _clientAddress, _amount);
            totalAssets[_bankId].totalAssetWithClient += _amount;
        }
        clientCount[_bankId][_branchId] += 1;
        return clientCount[_bankId][_branchId];
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    ) public virtual {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }

    function getLatestPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getConversionRateAmountInUSD(uint256 _amounInEUR)
        public
        view
        returns (uint256)
    {
        uint256 eurAmountInUsd = (_amounInEUR * getLatestPrice()) / 1e8;
        return (eurAmountInUsd);
    }

    function getConversionRateAmountInEUR(uint256 _amounInUSD)
        public
        view
        returns (uint256)
    {
        uint256 usdAmountInEur = (((_amounInUSD * 1e8) / getLatestPrice()));
        return (usdAmountInEur);
    }

    function B2BTradeUSDtoEUR(uint256 _amountInUSD, address _recipient) public {
        require(
            msg.sender == token1.getBankOwner() ||
                msg.sender == token2.getBankOwner(),
            "Not authorized"
        );
        _safeSwap(
            msg.sender,
            _recipient,
            _amountInUSD,
            getConversionRateAmountInEUR(_amountInUSD)
        );
    }

    function B2BTradeEURtoUSD(uint256 _amountInEUR, address _recipient) public {
        require(
            msg.sender == token1.getBankOwner() ||
                msg.sender == token2.getBankOwner(),
            "Not authorized"
        );

        _safeSwap(
            msg.sender,
            _recipient,
            _amountInEUR,
            getConversionRateAmountInUSD(_amountInEUR)
        );
    }

    function _safeSwap(
        address owner1,
        address owner2,
        uint256 amount1,
        uint256 amount2
    ) public {
        require(msg.sender == owner1 || msg.sender == owner2, "Not authorized");
        require(
            token1.allowance(owner1, address(this)) >= amount1,
            "Token 1 allowance too low"
        );
        require(
            token2.allowance(owner2, address(this)) >= amount2,
            "Token 2 allowance too low"
        );

        _safeTransferFrom(token1, owner1, owner2, amount1);
        _safeTransferFrom(token2, owner2, owner1, amount2);
    }

    struct Obligation {
        uint256 inUsd;
        uint256 inEur;
    }
    mapping(address => Obligation) obligations;

    struct forexRequest {
        uint256 fromBankId;
        uint256 fromBranchId;
        uint256 toBankId;
        uint256 toBranchId;
        uint256 amountInUsd;
        uint256 amountInEur;
        address byClient;
        address toClient;
        uint256 reqId;
        bool isDepositedToBranch;
        bool isSentToBank;
        bool isDone;
    }

    struct forexDetail{
        uint256 reqId;
        uint256 clientId;
        address byClient ;
        address toClient;
        bool isApproved;

    }
    // mapping(uint256 => mapping(uint256 => forexRequest)) public requests;
    // mapping(uint256 => mapping(uint256 => uint256)) public requestCount;
    mapping(address=>mapping(uint256=>forexRequest))public requestDetails;
    mapping(address=>uint256) public numOfRequest;
    mapping(address=>forexDetail) public forexDetails;

    function forexRequestToBranchOfBank1(
        uint256 _fromBankId,
        uint256 _fromBranchId,
        uint256 _clientId,
        uint256 _toBankId,
        uint256 _toBranchId,
        address _toClient,
        uint256 _amountInEur
    ) public returns (uint256 reqCount, uint256 _amount) {
        require(
            clients[_fromBankId][_clientId].client == msg.sender &&
                clients[_toBankId][_toBranchId].client == _toClient,
            "NOT A CLIENT"
        );
        require(_fromBankId == 0, "Not A correct Bank");
        require(
            token1.balanceOf(msg.sender) > _amountInEur,
            "Not Enoungh Funds"
        );
        require(
            token1.allowance(msg.sender, address(this)) >= _amountInEur,
            "Token Allowance is Low"
        );
        address user = msg.sender;

        _safeTransferFrom(
            token1,
            user,
            branches[_fromBranchId][_fromBranchId].branch,
            _amountInEur
        );
        obligations[banks[_toBankId].bank]
            .inUsd += getConversionRateAmountInUSD(_amountInEur);
        obligations[banks[_fromBankId].bank].inEur += _amountInEur;
        // requests[_fromBankId][
        //     requestCount[_fromBankId][
        //         clients[_fromBankId][_fromBranchId].clientId
        //     ]
        // ] = forexRequest(
        //     _fromBankId,
        //     _fromBranchId,
        //     _toBankId,
        //     _toBranchId,
        //     getConversionRateAmountInUSD(_amountInEur),
        //     _amountInEur,
        //     msg.sender,
        //     _toClient,
        //     requestCount[_fromBankId][
        //         clients[_fromBankId][_fromBranchId].clientId
        //     ],
        //     true,
        //     false,
        //     false
        // );

       requestDetails[user][numOfRequest[user]]= forexRequest(
            _fromBankId,
            _fromBranchId,
            _toBankId,
            _toBranchId,
            getConversionRateAmountInUSD(_amountInEur),
            _amountInEur,
            user,
            _toClient,
           numOfRequest[user],
            true,
            false,
            false
        );
        forexDetails[branches[_fromBankId][_fromBranchId].branch] = forexDetail( numOfRequest[user],_clientId,user,_toClient,false);
         forexDetails[branches[_toBankId][_toBranchId].branch] = forexDetail( numOfRequest[user],_clientId,user,_toClient,false);
        
        
        numOfRequest[user]++;
      
        return (
           numOfRequest[user] ,
            _amountInEur
        );
    }

    function forexRequestToBranchOfBank2(
        uint256 _fromBankId,
        uint256 _fromBranchId,
         uint256 _clientId,
        uint256 _toBankId,
        uint256 _toBranchId,
        address _toClient,
        uint256 _amountInUsd
    ) public returns (uint256 reqCount, uint256 _amount) {
        require(
            clients[_fromBankId][_clientId].client == msg.sender &&
                clients[_toBankId][_clientId].client == _toClient,
            "NOT A CLIENT"
        );
        require(_fromBankId == 1, "Not A correct BankID");
        require(
            token2.balanceOf(msg.sender) > _amountInUsd,
            "Not Enoungh Funds"
        );
        require(
            token2.allowance(msg.sender, address(this)) >= _amountInUsd,
            "Token Allowance is Low"
        );
        address user = msg.sender;

        _safeTransferFrom(
            token2,
            msg.sender,
            branches[_fromBranchId][_fromBranchId].branch,
            _amountInUsd
        );
        obligations[banks[_fromBankId].bank].inUsd += _amountInUsd;
        obligations[banks[_toBankId].bank]
            .inEur += getConversionRateAmountInEUR(_amountInUsd);
     
  requestDetails[msg.sender][numOfRequest[msg.sender]]= forexRequest(
            _fromBankId,
            _fromBranchId,
            _toBankId,
            _toBranchId,
            _amountInUsd,
            getConversionRateAmountInEUR(_amountInUsd),
            msg.sender,
            _toClient,
            numOfRequest[msg.sender]
            ,
            true,
            false,
            false
        );
forexDetails[branches[_fromBankId][_fromBranchId].branch] = forexDetail( numOfRequest[user],_clientId,user,_toClient,false);
forexDetails[branches[_toBankId][_toBranchId].branch] = forexDetail( numOfRequest[user],_clientId,user,_toClient,false);
         numOfRequest[user]++;
      
        return (
            numOfRequest[msg.sender],
            _amountInUsd
        );
    }

    function sendForexRequestToBank(
        uint256 _bankId,
        uint256 _branchId,
        uint256 _clientId,
        uint256 _reqId
    ) public {
        require(
            branches[_bankId][_branchId].branch == msg.sender,
            "Not A Branch"
        );
        require(_bankId == 0 || _bankId == 1, "Invalid BankId");
        address _user = clients[_bankId][_clientId].client;
        require(
            requestDetails[_user][_reqId].isDepositedToBranch,
            "Payment Is Due at branch"
        );
        requestDetails[_user][_reqId].isSentToBank = true;
        uint256 toBankId;
        uint256 toBranchId;
        toBankId =idOfAddress[requestDetails[_user][_reqId].toClient].bankId;
        toBranchId= idOfAddress[requestDetails[_user][_reqId].toClient].branchId;
        forexDetails[ branches[toBankId][toBranchId].branch].isApproved =true;
    }

    function processForexRequestByBranch(
        uint256 _byBankId,
        uint256 _byBranchId,
        uint256 _forBankId,
        uint256 _forBranchId,
        uint256 _reqNum
    ) public returns (bool success) {
        require(
            branches[_byBankId][_byBranchId].branch == msg.sender,
            "Not A Branch"
        );
         address user = clients[_forBankId][_forBranchId].client;
        require(
            requestDetails[user][_reqNum].isSentToBank,
            "Transaction Is not Verified by your Branch"
        );
        require(
            (_byBankId == 0 && _forBankId == 1) ||
                (_byBankId == 1 && _forBankId == 0),
            "Invalid BankId"
        );
       
        if (_byBankId == 0) {
            _safeTransferFrom(
                token1,
                msg.sender,
                requestDetails[user][_reqNum].toClient,
                requestDetails[user][_reqNum].amountInEur
            );
        } else {
            _safeTransferFrom(
                token2,
                msg.sender,
                requestDetails[user][_reqNum].toClient,
                requestDetails[user][_reqNum].amountInUsd
            );
        }
        return requestDetails[user][_reqNum].isDone = true;
    }

    function totalObligationOnBank(uint256 _bankId)
        public
        view
        returns (uint256 UDST, uint256 EUR)
    {
        require(banks[_bankId].bank == msg.sender, "ACCESS DENIED");
        require(_bankId == 0 || _bankId == 1, "Invalid bank ID");
        return (obligations[msg.sender].inUsd, obligations[msg.sender].inEur);
    }

    function settleTheObligationsForBanks(uint256 _bankId)
        public
        returns (bool)
    {
        require(_bankId == 0 || _bankId == 1, "Invalid bank ID");
        require(banks[_bankId].bank == msg.sender, "Access Denied");
        require(token1.balanceOf(msg.sender) > obligations[msg.sender].inEur);
        require(token2.balanceOf(msg.sender) > obligations[msg.sender].inUsd);
        require(
            token1.allowance(msg.sender, address(this)) >=
                obligations[msg.sender].inEur ||
                token2.allowance(msg.sender, address(this)) >=
                obligations[msg.sender].inUsd,
            "Token Allowance is Low"
        );
        if (_bankId == 0) {
            _safeTransferFrom(
                token1,
                msg.sender,
                token2.getBankOwner(),
                obligations[msg.sender].inEur
            );
            obligations[msg.sender].inEur = 0;
            _safeTransferFrom(
                token2,
                msg.sender,
                banks[_bankId].bank,
                obligations[msg.sender].inUsd
            );
            obligations[msg.sender].inUsd = 0;
        } else {
            _safeTransferFrom(
                token1,
                msg.sender,
                banks[_bankId].bank,
                obligations[msg.sender].inEur
            );
            obligations[msg.sender].inEur = 0;
            _safeTransferFrom(
                token2,
                msg.sender,
                banks[_bankId].bank,
                obligations[msg.sender].inUsd
            );
            obligations[msg.sender].inUsd = 0;
        }
        return true;
    }

    struct Position {
        uint256 bankId;
        uint256 branchId;
        uint256 clientId;
        uint256 positionId;
        uint256 amountBorrowed;
        uint256 amountDeposited;
        uint256 timeStamp;
        bool isBorrowed;
        bool isDone;
        bool isClear;
    }
    struct borrowDetail{
    uint256 positionId;
    uint256 clientId;
     address byClient ;
     address toBranch;
     bool isApproved;
    }

    // mapping(uint256 => mapping(uint256 => Position)) public positions1;
    // //mapping from branchId to numof position
    // mapping(uint256 => uint256) public positionCount1;
    // //for bank1 clientId to positionId
    // mapping(uint256 => mapping(uint256 => Position)) public positions2;
    // mapping(uint256 => uint256) public positionCount2;

    //for bank2 clientId to positionId
 mapping(address=>uint256) public numOfPosition;
 // mapping client address to position id
 mapping(address => mapping(uint256 => Position)) public positionDetails;
 //client address and positionid to position struct.
 mapping(address=>borrowDetail) public borrowDetails;



// by client
    function borrowRequest(  uint256 _bankId,
        uint256 _clientId,
        uint256 _amount) public 
   {
       address _clientAddress = msg.sender;
       uint256 index =numOfPosition[_clientAddress];
       require(_clientAddress==clients[_bankId][_clientId].client,"INVALID CLIENT");
  if(_bankId== 0){
        positionDetails[_clientAddress][index].amountBorrowed =_amount;
        positionDetails[_clientAddress][index].isBorrowed = true;
        positionDetails[_clientAddress][index].bankId  =_bankId;
        positionDetails[_clientAddress][index].clientId =_clientId;
        positionDetails[_clientAddress][index].positionId = index;
         uint256 branchId=idOfAddress[_clientAddress].branchId;
         address branchAddress =branches[_bankId][branchId].branch;
         borrowDetails[branchAddress] = borrowDetail(index,_clientId,_clientAddress,branchAddress,false);
        
        numOfPosition[_clientAddress]++;
  }
  else{
        positionDetails[_clientAddress][index].amountBorrowed =_amount;
        positionDetails[_clientAddress][index].isBorrowed = true;
        positionDetails[_clientAddress][index].bankId  =_bankId;
         positionDetails[_clientAddress][index].clientId =_clientId;
         positionDetails[_clientAddress][index].positionId = index;

          uint256 branchId=idOfAddress[_clientAddress].branchId;
         address branchAddress =branches[_bankId][branchId].branch;
         borrowDetails[branchAddress] = borrowDetail(index,_clientId,_clientAddress,branchAddress,false);
         numOfPosition[_clientAddress]++;

  }
       
       
    }
    


    // mapping(uint256=>uint256) iRateOfBorrowing;
    //    function setInterestRate (uint256 _bankId,uint _iR) public {
    //        require(banks[_bankId].bank==msg.sender,"Access Denied");
    //        iRateOfBorrowing[_bankId]=_iR;
    //    }

// by branch of the client
    function processLoan(
        uint256 _bankId,
        uint256 _branchId,
        uint256 _clientId,
        uint256 _positionId
       
    ) public returns (bool) {
        require(_bankId == 0 || _bankId == 1, "Invalid bank ID");
        require( branches[_bankId][_branchId].branch == msg.sender,"Invalid  Branch");
        address _clientAddress = clients[_bankId][_clientId].client;
        if (_bankId == 0) {
            _safeTransferFrom(
                token1,
                branches[_bankId][_branchId].branch,
              _clientAddress,
             positionDetails[_clientAddress][_positionId].amountBorrowed
            );
             positionDetails[_clientAddress][_positionId].timeStamp = block.timestamp; 
             positionDetails[_clientAddress][_positionId].isDone = true;
        } else {
            _safeTransferFrom(
                token2,
                branches[_bankId][_branchId].branch,
                _clientAddress,
                 positionDetails[_clientAddress][_positionId].amountBorrowed
            );
            positionDetails[_clientAddress][_positionId].timeStamp =  block.timestamp;
             positionDetails[_clientAddress][_positionId].isDone =true;
            
            
        }

        return true;
    }

    function calculateInterest(
        uint256 iR,
        uint256 _amount,
        uint256 numOfDays
    ) public pure returns (uint256) {
        return (iR * _amount * numOfDays) / 100 / 365;
    }

    function calculateNumOfDays(
        uint256 _bankId,
        uint256 _branchId,
        uint256 _positionId
   
    ) public view returns (uint256) {
        address _user =clients[_bankId][_branchId].client;
        if (_bankId == 0) {
            return
                (block.timestamp -
                    positionDetails[_user][_positionId]
                        .timeStamp) /
                60 /
                60 /
                24;
        } else {
            return
                (block.timestamp -
                    positionDetails[_user][_positionId]
                        .timeStamp) /
                60 /
                60 /
                24;
        }
    }
// by client
    function clearLoan(
        uint256 _bankId,
        uint256 _branchId,
        uint256 _positionId,
        uint256 _clientId
      
    ) public {
        require(_bankId == 0 || _bankId == 1, "Invalid bank ID");
        require(
            clients[_bankId][_clientId].clientId ==
                _clientId &&
                clients[_bankId][_clientId].branchId ==
                _branchId,
            "Invalid clientID or BranchID"
        );
        address user =msg.sender;
        uint256 interestAmount = calculateInterest(
                   10,
                    positionDetails[user][_positionId]
                        .amountBorrowed,
                    calculateNumOfDays(_bankId, _branchId,_positionId)
                );
                uint256 payableAmount =positionDetails[user][_positionId].amountBorrowed +interestAmount;

      
        if (_bankId == 0) {
            _safeTransferFrom(
                token1,
                msg.sender,
                branches[_bankId][_branchId].branch,
                payableAmount
            );
            positionDetails[user][_positionId].isBorrowed = false;
            positionDetails[user][_positionId].isClear =true;
             
        } else {
            _safeTransferFrom(
                token2,
                msg.sender,
                branches[_bankId][_branchId].branch,
                payableAmount
            );
            positionDetails[user][_positionId].isBorrowed = false;
             positionDetails[user][_positionId].isClear =true;

        }
    }
}
