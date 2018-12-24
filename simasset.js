/*!
 * SimAsset.js
 * This is an interface for accessing SimAsset.sol.
 * This supports many developers to develop various Dapps.
 *
 * Copyright (c) 2018 TANUSUKE
 * Released under the LGPL license.
 * see https://www.gnu.org/licenses/lgpl-3.0.html 
 *
 */
const SimAsset = (function() {
    'use strict';

    const SimAsset = function(require) {
        if(!(this instanceof SimAsset)) {
            return new SimAsset(require);
        }
        this.util = require('ethereumjs-util');
        this.tx = require('ethereumjs-tx');
    }

    /**
	* @void setProvider : Specify the Ethereum node and chain to use (must to execute)
	* @string node : Address of the Ethereum node
	* @string chain : Kind of the Ethereum network
	*/
	SimAsset.prototype.setProvider = function(node,chain){
		this.node = node;
		switch(chain){
			case 'mainnet':
				this.chainId = 1;
				break;
			case 'ropsten':              
				this.chainId = 3;
				break;
			case 'rinkeby':              
				this.chainId = 4;
				break;
			case 'kovan':              
				this.chainId = 42;
				break;
			default:
				this.chainId = chain;
				break;
		}
		const address = ajax({ url: 'config/contract.address', type: "GET", dataType: "text", async:false}).responseText;
		const abi = JSON.parse( ajax({ url: 'config/abi.json',type: "GET",dataType: "json",async:false}).responseText );
		this.web3 = new Web3(new Web3.providers.HttpProvider(this.node));
		this.contract = this.web3.eth.contract(abi).at(address);
    }
    
    /**
	* @bool validateAddress : Validate the Ethereum address
	* @string address : Ethereum address
	*/
	function validateAddress(address){
		return String(address).length === 42 && String(address).match(/^[0-9a-zA-Z]/) && String(address).slice(0,2)=='0x';
    }
    
    /**
	* @bool validateSecret : Validate the Ethereum private key
	* @string secret : Ethereum private key
	*/
	function validateSecret(secret){
		return String(secret).length === 64 && String(secret).match(/^[0-9a-z]/)
    }
       
    /**
	* @object{string,int} getAccountBySecret : Acquire address and balance from private key
	* @string secret : Transaction sender's private key
	*/
	function getAccountBySecret(secret){
		if(validateSecret(secret)){
			const privkey = this.util.toBuffer('0x'+ secret);
			const address = '0x' + this.util.privateToAddress(privkey).toString('hex');
			if(validateAddress(address)){
					return {'address':address,'balance':this.web3.fromWei(this.web3.eth.getBalance(address), "ether").toNumber()};
			}else{
					return false;
			}
		}else{
			return false;
		}
    }
    
    /**
	* @promise sendTransaction : Send transaction to contract address
	* @string secret : Transaction sender's private key
	* @params transaction : Variables passed to the contract
	*/
    function sendTransaction(method,secret,...transaction){
        return new Promise( function(resolve, reject){			
			const account = getAccountBySecret(secret);
			if(!account){
				reject('Invalid secret.')
			}
			this.web3.eth.getTransactionCount(account.address, function(err,txCount){
				const privKey = this.util.toBuffer('0x'+ secret);
				const data = method.getData(...transaction, {from: account.address});
                const gasLimit = this.web3.eth.estimateGas({
                    "nonce": this.web3.toHex(txCount),
                    "from": account.address,
					"to": this.contract.address,
                    "data": data
                });
                const rawTx = {
					"nonce": this.web3.toHex(txCount),
					"gasPrice": web3.eth.gasPrice,
					"gasLimit": gasLimit,
					"to": this.contract.address,
					"value": this.web3.toHex(0),
					"data": data,
					"chainId": this.chainId
				};
				const tx = new this.tx(rawTx);
				tx.sign(privKey);
				const signedTx = tx.serialize();

				this.web3.eth.sendRawTransaction('0x' + signedTx.toString('hex'), function(err, txHash){
					if(err) {
						reject(err);
					} else {
						resolve(txHash);
					}
				});
			});
		});  
	}

	/**
    *  The following are functions for monitor events
    */  

	/**
	* @promise watchAssetSold : Monitor assets sold events
	* @object data{classId,serial,oldOwner,newOwner}
	*/
	SimAsset.prototype.watchAssetSold = function(){
		return new Promise(function(resolve, reject){
			this.contract.AssetSold().watch(function (error, data) {
				if(error){
					reject(error);
				}
				resolve(data);
			}
		});
	}

	/**
	* @promise watchAccepted : Monitor the winning bidder confirmed events
	* @object data{classId,serial,owner,bidder,bidPrice,expire}
	*/
	SimAsset.prototype.watchAccepted = function(){
		return new Promise(function(resolve, reject){
			this.contract.Accepted().watch(function (error, data) {
				if(error){
					reject(error);
				}
				resolve(data);
			}
		});
	}
	 
	/**
	* @promise watchBid : Monitor bidding events
	* @object data{classId,serial,owner,bidder,bidPrice}
	*/
	SimAsset.prototype.watchBid = function(){
		return new Promise(function(resolve, reject){
			this.contract.Bid().watch(function (error, data) {
				if(error){
					reject(error);
				}
				resolve(data);
			}
		});
	}

	
    /**
    * The following are functions for managing asset classes
    */ 

	/**
	* @promise createAssetClass : Define the asset class for the distributed application you create
	* @string secret : Transaction sender's private key
	* @string name : Asset class identifier by string name
	* @int defaultPrice : Initial price of asset that the administrator of the asset class can specify
	* @int minTransfer :  Minimum transfer amount that the administrator of the asset class can specify  
	* @int maxTransfer :  Maximum transfer amount that the administrator of the asset class can specify  
	* @float feeRate : Transaction fee rate the administrator of the asset class receive (Percentage of two decimal places) 
	* @int minExpire : The minimum value of the period from the point of successful biddtake the asset (specified by the number of blocks) 
	* @bool exchangable : Whether anyone can trade assets within this asset class
	*/
	SimAsset.prototype.createAssetClass = function(secret, name, defaultPrice, minTransfer, maxTransfer, feeRate, minExpire, exchangable){
        return sendTransaction(this.contract.createAssetClass, secret, name, defaultPrice, minTransfer, maxTransfer, feeRate, minExpire, exchangable);
    }
    
	/**
	* @promise setNameOfAssetClass : Rename the asset class you created
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @string name : Asset class identifier by string name
	*/
    SimAsset.prototype.setNameOfAssetClass = function(secret, classId, name){
        return sendTransaction(this.contract.setNameOfAssetClass, secret, classId, name);
    }

	/**
	* @promise setDefaultPrice : Set the initial price of the asset in the asset class you created
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @int defaultPrice : Initial price of asset that asset manager can specify
	*/
    SimAsset.prototype.setDefaultPrice = function(secret, classId, defaultPrice){
        return sendTransaction(this.contract.setDefaultPrice, secret, classId, defaultPrice);
    }

	/**
	* @promise setMinTransfer : Set the minimum amount of transaction within the asset class you created
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @int minTransfer :  Minimum transfer amount  that asset manager can specify 
	*/
    SimAsset.prototype.setMinTransfer = function(secret, classId, minTransfer){
        return sendTransaction(this.contract.setMinTransfer, secret, classId , minTransfer);
    }

	/**
	* @promise setMaxTransfer : Set the maximum amount of transaction within the asset class you created
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @int maxTransfer :  Maximum transfer amount  that asset manager can specify 
	*/
    SimAsset.prototype.setMaxTransfer = function(secret, classId, maxTransfer){
        return sendTransaction(this.contract.setMaxTransfer, secret, classId, maxTransfer);
    }

	/**
	* @promise setFeeRate : Set transaction fee rate the administrator of the asset class receive (Percentage of two decimal places)
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @float feeRate : Transaction fee rate (Percentage of two decimal places)
	*/
    SimAsset.prototype.setFeeRate = function(secret, classId, feeRate){
        return sendTransaction(this.contract.setFeeRate, secret, classId, ~~(feeRate*100));
    }

	/**
	* @promise setMinExpire : Set the minimum value of the period from the point of successful bidding that the bidder can take the asset (specified by the number of blocks)
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @int minExpire : The minimum value of the period from the point of successful bidding that the bidder can take the asset (specified by the number of blocks)
	*/
    SimAsset.prototype.setMinExpire = function(secret, classId, minExpire){
        return sendTransaction(this.contract.setMinExpire, secret, classId, minExpire);
    }

	/**
	* @promise defineMeta : Define the meta information to use within the asset class you created
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @string key : Key of the meta information
	* @bool private : Whether non-owner can view the contents of meta information
	* @bool keep : Whether to inherit meta information when asset ownership transfers
	*/
    SimAsset.prototype.defineMeta = function(secret, classId, key, private, keep){
        return sendTransaction(this.contract.defineMeta, secret, classId, key, private, keep);
    }

	/**
	* @promise acceptToChangeAdmin : Nominate a new administrator for the asset class you created
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @string newAdmin : New administrator of the asset class
	*/
    SimAsset.prototype.acceptToChangeAdmin = function(secret, classId, newAdmin){
        return sendTransaction(this.contract.acceptToChangeAdmin, secret, classId, newAdmin);
    }

	/**
	* @promise changeAdmin : Confirm change of administrator of asset class by new administrator
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	*/
    SimAsset.prototype.changeAdmin = function(secret, classId){
        return sendTransaction(this.contract.changeAdmin, secret, classId);
	}
	
    /**
    * The following are functions for managing assets
    */  

	/**
	* @promise assignMeta : Associate meta information with assets
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @int serial : Serial number of asset in the asset class 
	* @string key : Key of the meta information
	* @int fragment : Identifier in the same meta information key (This allows you to assign multiple values to the same key)
	* @string value : Value of the meta information
	*/
    SimAsset.prototype.assignMeta = function(secret, classId, serial, key, fragment, value){
        return sendTransaction(this.contract.assignMeta, secret, classId, serial, key, fragment, value);
    }

	/**
	* @promise buyAtAsk : Purchase assets at initial price or price suggested by old owner
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @int serial : Serial number of asset in the asset class 
	* @int newAskPrice : New selling price (Specify 0 to make purchase impossible) 
	*/
    SimAsset.prototype.buyAtAsk= function(secret, classId, serial, newAskPrice){
        return sendTransaction(this.contract.buyAtAsk, secret, classId, serial, newAskPrice);
	}

	/**
	* @promise setAsk : Set the ask price of the asset (Specify 0 to make purchase impossible) 
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @int serial : Serial number of asset in the asset class 
	* @int newAskPrice : New ask price of the asset (Specify 0 to make purchase impossible) 
	*/
    SimAsset.prototype.setAsk= function(secret, classId, serial, newAskPrice){
        return sendTransaction(this.contract.setAsk, secret, classId, serial, newAskPrice);
	}

	/**
	* @promise bid : Bid to purchase assets at prices lower than the offer price
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @int serial : Serial number of asset in the asset class 
	* @int bidPrice : Bid price
	*/
    SimAsset.prototype.bid= function(secret, classId, serial, bidPrice){
        return sendTransaction(this.contract.bid, secret, classId, serial, bidPrice);
	}
	
	/**
	* @promise accept : Allow confirmed bidder to purchase the asset
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @int serial : Serial number of asset in the asset class 
	* @int bidPrice : Bid price that bidder that the asset owner choose
	* @string bidder : Bidder that the asset owner choose
	* @int expire : Period from the point of successful bidding that the bidder can take the asset (specified by the number of blocks) 
	*/
    SimAsset.prototype.accept = function(secret, classId, serial, bidPrice, bidder, expire){
        return sendTransaction(this.contract.accept, secret, classId, serial, bidPrice, bidder, expire);
	}

	/**
	* @promise buyAfterAccept : Purchases the asset by successful bidder
	* @string secret : Transaction sender's private key
	* @int classId : Asset class identifier 
	* @int serial : Serial number of asset in the asset class 
	* @int newAskPrice : New selling price (Specify 0 to make purchase impossible) 
	*/
    SimAsset.prototype.buyAfterAccept = function(secret, classId, serial, newAskPrice){
        return sendTransaction(this.contract.buyAfterAccept, secret, classId, serial, newAskPrice);
	}

	/**
    * The following are functions for obtaining class informations
    */  

	/**
	* @int getClassId : Get asset class identifier by asset class name
	* @string name : Asset class identifier by name
	*/
	SimAsset.prototype.getClassId = function(name){
		return this.contract.getClassId(name);
	}
	
	/**
	* @array[int] getWholeClassId : Get all asset class identifiers
	*/
	SimAsset.prototype.getWholeClassIds = function(){
		return this.contract.getWholeClassIds();
	}

	/**
	* @string getNameByClassId : Get asset class name by asset class identifier
	* @int classId : Asset class identifier 
	*/
	SimAsset.prototype.getNameByClassId = function(classId){
		return this.contract.getNameByClassId(classId);
	}

	/**
	* @string getAdminByClassId : Get administrator of asset class by asset class identifier
	* @int classId : Asset class identifier 
	*/
	SimAsset.prototype.getAdminByClassId = function(classId){
		return this.contract.getAdminByClassId(classId);
	}

	/**
	* @int getDefaultPriceByClassId : Get initial price of asset in asset class by asset class identifier
	* @int classId : Asset class identifier 
	*/
	SimAsset.prototype.getDefaultPriceByClassId = function(classId){
		return this.contract.getDefaultPriceByClassId(classId);
	}

	/**
	* @int getMinTransferByClassId : Get minimum amount of transfer in asset class by asset class identifier
	* @int classId : Asset class identifier 
	*/
	SimAsset.prototype.getMinTransferByClassId = function(classId){
		return this.contract.getMinTransferByClassId(classId);
	}

	/**
	* @int getMaxTransferByClassId : Get maximum amount of transfer in asset class by asset class identifier
	* @int classId : Asset class identifier 
	*/
	SimAsset.prototype.getMaxTransferByClassId = function(classId){
		return this.contract.getMaxTransferByClassId(classId);
	}

	/**
	* @float getFeeRateByClassId : Get the rate of transaction fee that the administrator of the asset class receive 
	* @int classId : Asset class identifier 
	*/
	SimAsset.prototype.getFeeRateByClassId = function(classId){
		return this.contract.getFeeRateByClassId(classId)*0.01;
	}

	/**
	* @int getMinExpireByClassId : Get the minimum value of the period from the point of successful biddtake the asset
	* @int classId : Asset class identifier 
	*/
	SimAsset.prototype.getMinExpireByClassId = function(classId){
		return this.contract.getMinExpireByClassId(classId);
	}
	
	/**
	* @int getAssetTotalByClassId : Get the total number of assets acquired in the asset class
	* @int classId : Asset class identifier 
	*/
	SimAsset.prototype.getAssetTotalByClassId = function(classId){
		return this.contract.getAssetTotalByClassId(classId);
	}

    /**
    * The following are functions for obtaining asset informations
    */  
	
	/**
	* @int getAssetId : Get asset identifier by class identifier and serial number
	* @int classId : Asset class identifier 
	* @int serial : Serial number of asset in the asset class 
	*/
	SimAsset.prototype.getAssetId = function(classId,serial){
		return this.contract.getAssetId(classId,serial);
	}

	/**
	* @array[int] getWholeAssetIds : Get all asset identifiers by within the asset class
	* @int classId : Asset class identifier 
	*/
	SimAsset.prototype.getWholeAssetIds = function(classId){
		return this.contract.getWholeAssetIds(classId);
	}

	/**
	* @int getLastByAssetId : Get the previous contract price by asset identifier
	* @int assetId : Asset identifier 
	*/
	SimAsset.prototype.getLastByAssetId = function(assetId){
		return this.contract.getLastByAssetId(assetId);
	}

	/**
	* @int getAskByAssetId : Get the ask price by asset identifier
	* @int assetId : Asset identifier 
	*/
	SimAsset.prototype.getAskByAssetId = function(assetId){
		return this.contract.getAskByAssetId(assetId);
	}

	/**
	* @int getBidByAssetId : Get highest bid price by asset identifier
	* @int assetId : Asset identifier 
	*/
	SimAsset.prototype.getBidByAssetId = function(assetId){
		return this.contract.getBidByAssetId(assetId);
	}

	/**
	* @string getOwnerByAssetId : Get current owner by asset identifier
	* @int assetId : Asset identifier 
	*/
	SimAsset.prototype.getOwnerByAssetId = function(assetId){
		return this.contract.getOwnerByAssetId(assetId);
	}

	/**
	* @string getBidderByAssetId : Get highest bidder by asset identifier
	* @int assetId : Asset identifier 
	*/
	SimAsset.prototype.getBidderByAssetId = function(assetId){
		return this.contract.getBidderByAssetId(assetId);
	}

	/**
	* @bool getAcceptedByAssetId : Get whether or not it has been bid successfully by asset identifier
	* @int assetId : Asset identifier 
	*/
	SimAsset.prototype.getAcceptedByAssetId = function(assetId){
		return this.contract.getAcceptedByAssetId(assetId);
	}

	/**
	* @int getExpireByAssetId : Get transfer deadline (block number) of the asset after it makes a successful bid 
	* @int assetId : Asset identifier 
	*/
	SimAsset.prototype.getExpireByAssetId = function(assetId){
		return this.contract.getExpireByAssetId(assetId);
	}

    /**
    * The following are functions for obtaining attributes of meta definitions
    */

	/**
	* @bool getMetaDefinitionPrivate : Get whether meta information is disclosed or not
	* @int classId : Asset class identifier 
	* @string key : Key of the meta information
	*/
	SimAsset.prototype.getMetaDefinitionPrivate= function(classId,key){
		return this.contract.getMetaDefinitionPrivate(classId,key);
	}

	/**
	* @bool getMetaDefinitionKeep : Get whether or not meta information is inherited when the ownership of the asset transferd
	* @int classId : Asset class identifier
	* @string key : Key of the meta information
	*/
	SimAsset.prototype.getMetaDefinitionKeep = function(classId,key){
		return this.contract.getMetaDefinitionKeep(classId,key);
	}

	/**
    *  The following are functions for obtaining meta information
    */   

	/**
	* @int getMetaValue : Get value of meta information
	* @int assetId : Asset identifier
	* @string key : Key of the meta information
	* @int fragment : Identifier in the same meta information key (This allows you to assign multiple values to the same key)
	*/
	SimAsset.prototype.getMetaValue = function(assetId,key,fragment){
		return this.contract.getMetaValue(assetId,key,fragment);
	}

    function ajax(option) {
        var xhr = new XMLHttpRequest();
        if(option.type==='GET'){
            xhr.open('GET', option.url, option.async);
            xhr.send(null);
            return xhr.status===200 ? xhr : null;
        }
    }
    
	return SimAsset;
})();


Object.defineProperty(window,'loadEthereumJS', {
    configurable: false,
    val: undefined,
    get: function () { return this.val; },
    set: function (require) {
        this.val = require;
        new SimAsset(require);
    }
});

