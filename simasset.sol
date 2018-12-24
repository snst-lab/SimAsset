pragma solidity ^0.4.4;

contract SimAsset{
    using safeMath for uint256;

    address private ROOT_ADMIN;
    uint256 private CONTRIBUTION_RATE; // CONTRIBUTION_RATE/10000

    /**
    * @struct AssetClass is incremented by the primary key 'classId'
    */
    struct AssetClass{
        bytes32[] name;
        address[] admin;
        address[] newAdmin;
        uint256[] defaultPrice;
        uint256[] minTransfer;
        uint256[] maxTransfer;
        uint256[] feeRate;  // feeRate/10000
        uint256[] minExpire;
        uint256[] total;
        bool[] exchangable;
    }
    AssetClass private assetClass;

    /**
    * @struct Asset is incremented by the primary key 'assetId'
    */
    struct Asset{
        uint256[] last;
        uint256[] ask;
        uint256[] bid;
        address[] bidder;
        address[] owner;
        bool[] accepted;
        uint256[] expire;
        uint256[][] metaIndex;
    }
    Asset private asset;
    
    /**
    * @struct MetaDefinition is incremented by the primary key 'metaDefinitionIndex' and associated with struct AssetClass in 'classId'
    */
    struct MetaDefinition{
        bool[] secret;
        bool[] keep;
    }
    MetaDefinition private metaDefinition;

    /**
    * @struct Meta is incremented by the primary key 'metaIndex' and associated with struct Asset in 'assetId'
    */
    struct Meta{
        bytes32[] value;
        bool[] secret;
        bool[] keep;
    }
    Meta private meta;
    
    /**
    * @uint256 assetClassId[name]
    */
    mapping (bytes32 => uint256) internal assetClassId;

    /**
    * @uint256 assetId[classId][serial]
    */
    mapping (uint256 => mapping(uint256 => uint256)) internal assetId;
    
    /**
    * @uint256 metaDefinitionIndex[classId][key]
    */
    mapping (uint256 => mapping(bytes32 => uint256)) internal metaDefinitionIndex;
    
    /**
    * @uint256 metaIndex[assetId][key][fragment]
    */
    mapping (uint256 => mapping(bytes32 => mapping(uint256 => uint256))) internal metaIndex;

    event AssetSold(uint256 indexed classId, uint256 indexed serial, address oldOwner, address newOwner);
    event Accepted(uint256 indexed classId, uint256 indexed serial, address owner, address bidder, uint256 bidPrice, uint256 expire);
    event Bid(uint256 indexed classId, uint256 indexed serial, address owner, address bidder, uint256 bidPrice);
        
    constructor(string _ROOT_ADMIN, uint256 _newContributionRate) public{
        require(_newContributionRate <= 3000, 'The contribution rate is not a valid range.');
        ROOT_ADMIN = util.stringToAddress(_ROOT_ADMIN);
        SimAsset.initStructs();
    }

    /**
    * The following are functions for set/get system parameters
    */  
    modifier onlyROOT_ADMIN() {
        require(msg.sender == ROOT_ADMIN);
        _;
    }
    
    function changeROOT_ADMIN(string _newROOT_ADMIN) public onlyROOT_ADMIN {
        address newROOT_ADMIN = util.stringToAddress(_newROOT_ADMIN);
        require(ROOT_ADMIN != newROOT_ADMIN, 'The system parameters were not changed.');
        ROOT_ADMIN  = newROOT_ADMIN;
    }

    function changeContributionRate(uint256 _newContributionRate) public onlyROOT_ADMIN {
        require(CONTRIBUTION_RATE != _newContributionRate, 'The system parameters were not changed.');
        require(_newContributionRate <= 3000, 'New contribution rate is not a valid range.');
        CONTRIBUTION_RATE = _newContributionRate;
    }

    function getContractBalance() public view returns (uint256){
        return address(this).balance;
    }

    /**
    *  Initialize structs
    */  
    function initStructs() internal{
        assetClass.name.push(0x0);
        assetClass.admin.push(0x0);
        assetClass.newAdmin.push(0x0);
        assetClass.defaultPrice.push(0);
        assetClass.minTransfer.push(0);
        assetClass.maxTransfer.push(0);
        assetClass.feeRate.push(0);
        assetClass.minExpire.push(0);
        assetClass.total.push(0);
        assetClass.exchangable.push(false);
        asset.last.push(0);
        asset.ask.push(0);
        asset.bid.push(0);
        asset.bidder.push(0x0);
        asset.owner.push(0x0);
        asset.accepted.push(false);
        asset.expire.push(0);
        uint256[] memory a = new uint256[](1);
        asset.metaIndex.push(a);
        metaDefinition.secret.push(false);
        metaDefinition.keep.push(false);
        meta.secret.push(false);
        meta.keep.push(false);
        meta.value.push(0x0);
    }

    /**
    * The following are functions for managing asset classes
    */ 
    function createAssetClass(string _name, uint256 _defaultPrice, uint256 _minTransfer, uint256 _maxTransfer, uint256 _feeRate, uint256 _minExpire, bool _exchangable) public returns(uint256){
        bytes32 name = util.stringToBytes32(_name);
        require(assetClassId[name]==0, 'A class with the same name already exists.');
        require(_minTransfer <= _maxTransfer, 'The range of transfer amount is not a valid range.');
        require(_minTransfer <= _defaultPrice && _defaultPrice <= _maxTransfer , 'The default price is not a valid range.');
        require( 4096 <= _minExpire || _minExpire == 0, 'Minimum exprire block must be a number of 4096 or more.');
        require(_feeRate <= 3000, 'The fee rate or the contribute rate is not a valid range.');

        if(_minTransfer == 0){_minTransfer == 1e10;}
        if(_maxTransfer == 0){_maxTransfer == 1e38;}
        if(_minExpire == 0){_minExpire == 4096;}
    
        assetClass.name.push(name);
        assetClass.admin.push(msg.sender);
        assetClass.defaultPrice.push(_defaultPrice);
        assetClass.minTransfer.push(_minTransfer);
        assetClass.maxTransfer.push(_maxTransfer);
        assetClass.feeRate.push(_feeRate);
        assetClass.minExpire.push(_minExpire);
        assetClass.exchangable.push(_exchangable);

        assetClassId[name] = assetClass.name.length-1;
        
        return assetClassId[name];
    }

    function setNameOfAssetClass(uint256 _classId, string _name) public returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(msg.sender == assetClass.admin[_classId], 'Only the administrator of the asset class can define meta informations.');
        bytes32 newName = util.stringToBytes32(_name);
        require(assetClassId[newName]==0, 'A class with the same name already exists.');
        bytes32 oldName = assetClass.name[_classId];
        assetClass.name[_classId] = newName;
        assetClassId[newName] = _classId;
        assetClassId[oldName] = 0;

        return _classId;
    }

    function setDefaultPrice(uint256 _classId, uint256 _defaultPrice) public returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(msg.sender == assetClass.admin[_classId], 'Only the administrator of the asset class can define meta informations.');
        uint256 minTransfer = assetClass.minTransfer[_classId];
        uint256 maxTransfer = assetClass.maxTransfer[_classId];
        require(minTransfer <= _defaultPrice && _defaultPrice <= maxTransfer , 'The default price is not a valid range.');

        assetClass.defaultPrice[_classId] = _defaultPrice;

        return _classId;
    }

    function setMinTransfer(uint256 _classId, uint256 _minTransfer) public returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(msg.sender == assetClass.admin[_classId], 'Only the administrator of the asset class can define meta informations.');
        uint256 maxTransfer = assetClass.maxTransfer[_classId];
        uint256 defaultPrice = assetClass.defaultPrice[_classId];
        require(_minTransfer <= maxTransfer, 'The range of transfer amount is not a valid range.');
        require(_minTransfer <= defaultPrice && defaultPrice <= maxTransfer , 'The default price is not a valid range.');

        assetClass.minTransfer[_classId] = _minTransfer;

        return _classId;
    }
    
    function setMaxTransfer(uint256 _classId, uint256 _maxTransfer) public returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(msg.sender == assetClass.admin[_classId], 'Only the administrator of the asset class can define meta informations.');
        uint256 minTransfer = assetClass.minTransfer[_classId];
        uint256 defaultPrice = assetClass.defaultPrice[_classId];
        require(minTransfer <= _maxTransfer, 'The range of transfer amount is not a valid range.');
        require(minTransfer <= defaultPrice && defaultPrice <= _maxTransfer , 'The default price is not a valid range.');

        assetClass.maxTransfer[_classId] = _maxTransfer;

        return _classId;
    }

    function setFeeRate(uint256 _classId, uint256 _feeRate) public returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(msg.sender == assetClass.admin[_classId], 'Only the administrator of the asset class can define meta informations.');
        require(_feeRate <= 3000 , 'The fee rate or the contribute rate is not a valid range.');

        assetClass.feeRate[_classId] = _feeRate;

        return _classId;
    }

    function setMinExpire(uint256 _classId, uint256 _minExpire) public returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(msg.sender == assetClass.admin[_classId], 'Only the administrator of the asset class can define meta informations.');
        require(4096 <= _minExpire, 'Minimum exprire block must be a number of 4096 or more.');

        assetClass.minExpire[_classId] = _minExpire;

        return _classId;
    }

    function defineMeta(uint256 _classId, string _key, bool _secret, bool _keep) public returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(msg.sender == assetClass.admin[_classId], 'Only the administrator of the asset class can define meta informations.');
        
        bytes32 key = util.stringToBytes32(_key);
        require(metaDefinitionIndex[_classId][key]==0,'A key with the same name is already defined.');

        metaDefinitionIndex[_classId][key] = metaDefinition.secret.length-1;
        metaDefinition.secret.push(_secret);
        metaDefinition.keep.push(_keep);

        return metaDefinitionIndex[_classId][key];
    }

    function acceptToChangeAdmin(uint256 _classId, string _newAdmin) public returns(uint256){
        address newAdmin = util.stringToAddress(_newAdmin);
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(msg.sender == assetClass.admin[_classId], 'Only the administrator can sell the asset class.');
        require(msg.sender != newAdmin, 'The same address as the current administrator was specified.');
  
        assetClass.newAdmin[_classId] = newAdmin;

        return _classId;
    }

    function chageAdmin(uint256 _classId) public returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(msg.sender == assetClass.newAdmin[_classId], 'You do not have permission to purchase this asset class.');
        
        assetClass.admin[_classId] = msg.sender;
        assetClass.newAdmin[_classId] = address(0);

        return _classId;
    }

    /**
    * The following are functions for managing assets
    */  
    function assignMeta(uint256 _classId, uint256 _serial, string _key, uint256 _fragment, string _value) public returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(0< _serial  && _serial <= assetClass.total[_classId], 'The serial is not a valid range.');
        uint256 id = assetId[_classId][_serial];
        require(msg.sender == asset.owner[id], 'Only the owner of the asset can assign meta informations.');
        
        bytes32 key = util.stringToBytes32(_key);
        
        uint256 idx = metaDefinitionIndex[_classId][key];
        require(idx > 0, 'The key of meta information was not found in the asset class.');
        
        uint256 jdx = metaIndex[id][key][_fragment];
        bytes32 value = util.stringToBytes32(_value);

        if(jdx==0){
            meta.value.push(value);
            meta.keep.push(metaDefinition.keep[idx]);
            meta.secret.push(metaDefinition.secret[idx]);
            metaIndex[id][key][_fragment] = meta.value.length-1;
            asset.metaIndex[id].push(meta.value.length-1);
        }else{
            meta.value[jdx] = value;
        }
        return metaIndex[id][key][_fragment];
    }
    
    function buyAtAsk(uint256 _classId, uint256 _serial, uint256 _newAsk) public payable returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(0< _serial  && _serial <= assetClass.total[_classId], 'The serial is not a valid range.');
        require(msg.sender.balance > msg.value, 'Your balance is not enough.');
        require(msg.value >= assetClass.minTransfer[_classId], 'The transfer amount is not a valid range.');
        require(_newAsk >= assetClass.minTransfer[_classId] || _newAsk==0, 'New ask price is not a valid range.');
        require(_newAsk <= assetClass.maxTransfer[_classId], 'New ask price is not a valid range.');
        
        uint256 id = assetId[_classId][_serial];
        require(msg.sender != asset.owner[id], 'You are the owner of this asset.');
        if(id==0){
            require(msg.value >= assetClass.defaultPrice[_classId], 'The transfer amount is not enough.');

            uint256 sendToAdmin = uint(safeMath.mul( assetClass.defaultPrice[_classId], safeMath.sub(1, safeMath.div(CONTRIBUTION_RATE,10000))));
            uint256 sendToROOT_ADMIN = uint(safeMath.mul( assetClass.defaultPrice[_classId], safeMath.div(CONTRIBUTION_RATE,10000)));
            assetClass.admin[_classId].transfer(sendToAdmin);
            ROOT_ADMIN.transfer(sendToROOT_ADMIN);

            asset.last.push(assetClass.defaultPrice[_classId]);
            if(assetClass.exchangable[_classId]){asset.ask.push(_newAsk);}else{asset.ask.push(0);}
           
            asset.bid.push(0);
            asset.bidder.push(address(0));
            asset.accepted.push(false);
            asset.expire.push(0);
            assetClass.total[_classId]++;
            assetId[_classId][assetClass.total[_classId]]=asset.last.length-1;
            
            emit AssetSold(_classId, _serial, assetClass.admin[_classId], msg.sender);
        }
        else{
            require(assetClass.exchangable[_classId], 'Assets can not be exchanged in this asset class.');
            require(asset.ask[id]!=0, 'This asset is not for sale.');
            require(msg.value >= asset.ask[id], 'The transfer amount is not enough.');

            uint256 sendToOwner_ = uint(safeMath.mul( asset.ask[id], safeMath.sub(1, safeMath.div(assetClass.feeRate[_classId],10000))));
            uint256 sendToAdmin_ = uint(safeMath.mul( asset.ask[id], safeMath.div(assetClass.feeRate[_classId],10000)));
            asset.owner[id].transfer(sendToOwner_);
            assetClass.admin[_classId].transfer(sendToAdmin_);

            asset.last[id]  = asset.ask[id];
            asset.ask[id] = _newAsk;
            asset.bid[id] = 0;
            asset.bidder[id] = address(0);
            asset.accepted[id] = false;
            asset.expire[id] = 0;
            
            for (uint i=0; i<asset.metaIndex[id].length; i++){
               if(!meta.keep[asset.metaIndex[id][i]]){
                  meta.value[asset.metaIndex[id][i]] = 0x0;  
               }
            }

            emit AssetSold(_classId, _serial, asset.owner[id], msg.sender);
        }
        return assetId[_classId][_serial];
    }

    function setAsk(uint256 _classId, uint256 _serial, uint256 _newAsk) public returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(assetClass.exchangable[_classId], 'Assets can not be exchanged in this asset class.');
        require(0< _serial  && _serial <= assetClass.total[_classId], 'The serial is not a valid range.');
        uint256 id = assetId[_classId][_serial];
        require(msg.sender == asset.owner[id], 'Only the owner of the asset can change ask price.');
        
        asset.ask[id] = _newAsk;
        return id;
    }

    function bid(uint256 _classId, uint256 _serial, uint256 _bid) public returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(assetClass.exchangable[_classId], 'Assets can not be exchanged in this asset class.');
        require(0< _serial  && _serial <= assetClass.total[_classId], 'The serial is not a valid range.');
        uint256 id = assetId[_classId][_serial];
        require(id > 0, 'This asset is not bidding.');
        require(msg.sender != asset.owner[id], 'You are the owner of this asset.');
        require(_bid > asset.bid[id], 'Please set a price higher than the current bid price.');
        require(asset.accepted[id]==false || block.number > asset.expire[id], 'It is the waiting period for transfer to the successful bidder now.');
        
        asset.bid[id] = _bid;
        asset.bidder[id] = msg.sender;
    
        emit Bid(_classId, _serial, asset.owner[id], asset.bidder[id], _bid);
        return id;
    }

    function accept(uint256 _classId, uint256 _serial, uint256 _bid, string _bidder, uint256 _expire) public returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(assetClass.exchangable[_classId], 'Assets can not be exchanged in this asset class.');
        require(0< _serial  && _serial <= assetClass.total[_classId], 'The serial is not a valid range.');
        require(assetClass.minExpire[_classId] < _expire , 'Expriration block is too short.');
        uint256 id = assetId[_classId][_serial];
        require(msg.sender == asset.owner[id], 'Only the owner of the asset can accept.');
        require(_bid == asset.bid[id], 'An incorrect bid price was specified.');
        address bidder = util.stringToAddress(_bidder);
        require(bidder == asset.bidder[id], 'An incorrect bidder address was specified.');
        
        asset.accepted[id] = true;
        asset.expire[id] = safeMath.add(block.number, _expire);
        
        emit Accepted(_classId, _serial, asset.owner[id], asset.bidder[id], _bid, asset.expire[id]);
        return id;
    }

    function buyAfterAccept(uint256 _classId, uint256 _serial, uint256 _newAsk) public payable returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(assetClass.exchangable[_classId], 'Assets can not be exchanged in this asset class.');
        require(0< _serial  && _serial <= assetClass.total[_classId], 'The serial is not a valid range.');
        uint256 id = assetId[_classId][_serial];
        require(id > 0, 'This asset is not bidding.');
        require(block.number <= asset.expire[id], 'The transfer deadline has expired.');
        require(msg.sender == asset.bidder[id] && asset.accepted[id], 'You are not successful bidder of this asset.');
        require(msg.sender.balance > msg.value, 'Your balance is not enough.');
        require(msg.value >= assetClass.minTransfer[_classId], 'The transfer amount is not a valid range.');
        require((_newAsk >= assetClass.minTransfer[_classId] && _newAsk <= assetClass.maxTransfer[_classId] ) || _newAsk==0, 'New ask price is not a valid range.');
        require(msg.value >= asset.bid[id], 'The transfer amount is not enough.');

        uint256 sendToOwner_ = uint(safeMath.mul( asset.ask[id], safeMath.sub(1, safeMath.div(assetClass.feeRate[_classId],10000))));
        uint256 sendToAdmin_ = uint(safeMath.mul( asset.ask[id], safeMath.div(assetClass.feeRate[_classId],10000)));
        asset.owner[id].transfer(sendToOwner_);
        assetClass.admin[_classId].transfer(sendToAdmin_);

        asset.last[id] = asset.bid[id];
        asset.ask[id] = _newAsk;
        asset.bidder[id] = address(0);
        asset.accepted[id] = false;
        asset.expire[id] = 0;
        
        for (uint i=0; i<asset.metaIndex[id].length; i++){
           if(meta.keep[asset.metaIndex[id][i]]){
              meta.value[asset.metaIndex[id][i]] = 0x0;  
           }
        }
    
        emit AssetSold(_classId, _serial, asset.owner[id], msg.sender);
        return id;
    }

    /**
    * The following are functions for obtaining class informations
    */  
    function getClassId(string _name) public view returns(uint256){
        bytes32 name = util.stringToBytes32(_name);
        return assetClassId[name];
    }
    
    function getWholeClassIds() public view returns(uint256[]){
        uint256[] memory array;
        for(uint i=1; i< assetClass.name.length; i++){
            array[i] = i;
        }
        return array;
    }
    
    function getNameByClassId(uint256 _classId) public view returns(bytes32){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        return assetClass.name[_classId];
    }

    function getAdminByClassId(uint256 _classId) public view returns(address){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        return assetClass.admin[_classId];
    }

    function getDefaultPriceByClassId(uint256 _classId) public view returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        return assetClass.defaultPrice[_classId];
    }

    function getMinTransferByClassId(uint256 _classId) public view returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        return assetClass.minTransfer[_classId];
    }

    function getMaxTransferByClassId(uint256 _classId) public view returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        return assetClass.maxTransfer[_classId];
    }

    function getFeeRateByClassId(uint256 _classId) public view returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        return assetClass.feeRate[_classId];
    }

    function getMinExpireByClassId(uint256 _classId) public view returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        return assetClass.minExpire[_classId];
    }

    function getAssetTotalByClassId(uint256 _classId) public view returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        return assetClass.total[_classId];
    }

    /**
    * The following are functions for obtaining asset informations
    */  
    function getAssetId(uint256 _classId, uint256 _serial) public view returns(uint256){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        require(0< _serial  && _serial <= assetClass.total[_classId], 'The serial is not a valid range.');
        return assetId[_classId][_serial];
    }
    
    function getWholeAssetIds(uint256 _classId) public view returns(uint256[]){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        uint256[] memory array;
    
        for(uint i=1; i<= assetClass.total[_classId]; i++){
            array[i] = assetId[_classId][i];
        }
        return array;
    }

    function getLastByAssetId(uint256 _assetId) public view returns(uint256){
        require(0<_assetId && _assetId < asset.last.length, 'The asset id is not a valid range.');
        return asset.last[_assetId];
    }
    
    function getAskByAssetId(uint256 _assetId) public view returns(uint256){
        require(0<_assetId && _assetId < asset.last.length, 'The asset id is not a valid range.');
        return asset.ask[_assetId];
    }
    
    function getBidByAssetId(uint256 _assetId) public view returns(uint256){
        require(0<_assetId && _assetId < asset.last.length, 'The asset id is not a valid range.');
        return asset.bid[_assetId];
    }
    
    function getOwnerByAssetId(uint256 _assetId) public view returns(address){
        require(0<_assetId && _assetId < asset.last.length, 'The asset id is not a valid range.');
        return asset.owner[_assetId];
    }
    
    function getBidderByAssetId(uint256 _assetId) public view returns(address){
        require(0<_assetId && _assetId < asset.last.length, 'The asset id is not a valid range.');
        return asset.bidder[_assetId];
    }
    
    function getAcceptedByAssetId(uint256 _assetId) public view returns(bool){
        require(0<_assetId && _assetId < asset.last.length, 'The asset id is not a valid range.');
        return asset.accepted[_assetId];
    }
    
    function getExpireByAssetId(uint256 _assetId) public view returns(uint256){
        require(0<_assetId && _assetId < asset.last.length, 'The asset id is not a valid range.');
        return asset.expire[_assetId];
    }

    /**
    * The following are functions for obtaining attributes of meta definitions
    */
    function getMetaDefinitionSecret(uint256 _classId, string _key) public view returns(bool){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        bytes32 key = util.stringToBytes32(_key);
        uint256 idx = metaDefinitionIndex[_classId][key];
        return metaDefinition.secret[idx];
    }

    function getMetaDefinitionKeep(uint256 _classId, string _key) public view returns(bool){
        require(0<_classId && _classId < assetClass.name.length, 'The class id is not a valid range.');
        bytes32 key = util.stringToBytes32(_key);
        uint256 idx = metaDefinitionIndex[_classId][key];
        return metaDefinition.keep[idx];
    }

    /**
    *  The following are functions for obtaining meta information
    */   
    function getMetaValue(uint256 _assetId, string _key, uint256 _fragment) public view returns(bytes32){
        require(0<_assetId && _assetId < asset.last.length, 'The asset id is not a valid range.');
        bytes32 key = util.stringToBytes32(_key);
        uint256 idx = metaIndex[_assetId][key][_fragment];
        require(!meta.secret[idx], 'This meta information can only be viewed by the owner of the asset.');
        return meta.value[idx];
    }
 }
 
 
 library util{
    /**
    *  Convert string type to byte32 type.
    */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory temp = bytes(source);
        if (temp.length == 0) {
            return 0x0;
        }
        else if(temp.length>32){
            revert();
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
    /**
    *  Convert string type to address type.
    */
    function stringToAddress(string memory source) internal pure returns (address result) {
        bytes memory temp = bytes(source);
        if (temp.length != 20) {
            revert();
        }
        assembly {
            result := mload(add(source,20))
        } 
    }
}
 
 
 library safeMath {
    /**
    *  Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
          return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    /**
    *  Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    /**
    *  Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    /**
    *  Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}