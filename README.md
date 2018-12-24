# SimAsset

> These are a Dapp and Javascript SDK which can create arbitrary asset classes on Ethereum.
> These support you to develop various Dapps. 

*This library is in trial operation on the Ropsten network.  

<br>


## Contents

> [Installation](#installation)
>
> [Usage](#usage)
>
> [Functions](#functions)  
>- [Configuration](#configuration)
>- [Event Monitor](#event_monitor)
>- [Managing asset classes](#managing_asset_classes)
>- [Managing assets](#managing_assets)
>- [Obtaining class informations](#Obtaining_class_informations)
>- [Obtaining asset informations](#Obtaining_asset_informations)
>- [Obtaining attributes of meta definitions](#Obtaining_attributes_of_meta_definitions)
>- [Obtaining meta informations](#Obtaining_meta_informations)
>
> [Contributing](#contributing)  
>
> [License](#license)
>
> [Developer](#developer)  

<br>

---

<br>

>## Installation

### 1. Clone or Download

Clone this repo using `https://github.com/snst-lab/SimAsset` or download files separately to your local machine 


### 2. Place

 Place files in your working directory.  Below is an example.

```console
[Working Directory]
 |
 |_ config
 |     |_ contract.address  //Contract address of SimAsset.sol
 |     |
 |     |_ abi.json          //ABI of SimAsset.sol
 |     
 |_ lib
 |     |_ web3.min.js       //Ethereum Javascript API
 |     |
 |     |_ ethereumjs.js     //Ethereum Javascript API Extentions
 |     
 |     
 |_ simasset.js             //Javascript SDK of this Library
```

### 3. Load
 Load the library with script tag.

```html
 <script type="text/javascript" src="lib/web3.min.js"></script>
 <script type="text/javascript" src="lib/ethereumjs.js"></script>
 <script type="text/javascript" src="simasset.js"></script>
```
<br>
<br>

>## Usage

### Initialise App
```javascript
 const app = new SimAsset();

 app.setProvider('[Ethereum Node (ip of hostname)]','[Chain name (mainnet, ropsten, ...)]');
```
<br>
<br>

>## Functions
<br>

## Configuration

### SimAsset.prototype.setProvider (node, chain)
	@void setProvider : Specify the Ethereum node and chain to use (must to execute)
	@string node : Address of the Ethereum node
	@string chain : Kind of the Ethereum network 
 
#### example
```javascript
app.setProvider('localhost:8545','mainnet');
```
<br>

---

<br>

## Event_Monitor

### SimAsset.prototype.watchAssetSold ()
	@promise watchAssetSold : Monitor assets sold events
	@object data{classId,serial,oldOwner,newOwner}

#### example
```javascript
app.watchAssetSold().then((data)=>{
    const id = app.getAssetId(data.class,data.serial);
    if(id){
        alert(data.newOwner + ' bought the asset ' + id +' from '+data.oldOwner);
    }
).catch((error)=>{
    console.log(error);
});
```
<br>

### SimAsset.prototype.watchAccepted ()
	@promise watchAccepted : Monitor the winning bidder confirmed events
	@object data{classId,serial,owner,bidder,bidPrice,expire}

#### example
```javascript
app.watchAccepted().then((data)=>{
    const id = app.getAssetId(data.class,data.serial);
    if(id){
        alert(data.bidder + ' made a successful bid for the asset ' + id);
    }
).catch((error)=>{
    console.log(error);
});
```
<br>


### SimAsset.prototype.watchBid ()
	@promise watchBid : Monitor bidding events
	@object data{classId,serial,owner,bidder,bidPrice}

#### example
```javascript
app.watchBid().then((data)=>{
    const id = app.getAssetId(data.class,data.serial);
    if(id){
        alert(data.bidder + ' bid on the asset ' + id);
    }
).catch((error)=>{
    console.log(error);
});
```
<br>

---

<br>

## Managing_asset_classes

### SimAsset.prototype.createAssetClass (secret, name, defaultPrice, minTransfer, maxTransfer, feeRate, minExpire, exchangable)
	@promise createAssetClass : Define the asset class for the distributed application you create
	@string secret : Transaction sender's private key
	@string name : Asset class identifier by string name
	@int defaultPrice : Initial price of asset that the administrator of the asset class can specify
	@int minTransfer :  Minimum transfer amount that the administrator of the asset class can specify  
	@int maxTransfer :  Maximum transfer amount that the administrator of the asset class can specify  
	@float feeRate : Transaction fee rate the administrator of the asset class receive (Percentage of two decimal places) 
	@int minExpire : The minimum value of the period from the point of successful biddtake the asset (specified by the number of blocks) 
	@bool exchangable : Whether anyone can trade assets within this asset class

#### example
```javascript
app.createAssetClass('0xasdf...','MyAssetClass', 10e+16, 10e+10, 10e+35, 5.00, 4096, true);
```
<br>

### SimAsset.prototype.setNameOfAssetClass (secret, classId, name)
	@promise setNameOfAssetClass : Rename the asset class you created
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@string name : Asset class identifier by string name

#### example
```javascript
app.setNameOfAssetClass('0xasdf...', 1, 'NewAssetClass');
```
<br>

### SimAsset.prototype.setDefaultPrice (secret, classId, defaultPrice)
	@promise setDefaultPrice : Set the initial price of the asset in the asset class you created
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@int defaultPrice : Initial price of asset that asset manager can specify

#### example
```javascript
app.setDefaultPrice('0xasdf...', 1, 10e+17);
```
<br>


### SimAsset.prototype.setMinTransfer (secret, classId, minTransfer)
	@promise setMinTransfer : Set the minimum amount of transaction within the asset class you created
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@int minTransfer :  Minimum transfer amount  that asset manager can specify 

#### example
```javascript
app.setMinTransfer('0xasdf...', 1, 10e+11);
```
<br>


### SimAsset.prototype.setMaxTransfer (secret, classId, maxTransfer)
	@promise setMaxTransfer : Set the maximum amount of transaction within the asset class you created
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@int maxTransfer :  Maximum transfer amount  that asset manager can specify 

#### example
```javascript
app.setMaxTransfer('0xasdf...', 1, 10e+37);
```
<br>


###  SimAsset.prototype.setFeeRate (secret, classId, feeRate)
	@promise setFeeRate : Set transaction fee rate the administrator of the asset class receive (Percentage of two decimal places)
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@float feeRate : Transaction fee rate (Percentage of two decimal places)

#### example
```javascript
app.setFeeRate('0xasdf...', 1, 3.6);
```
<br>


###  SimAsset.prototype.setMinExpire (secret, classId, minExpire)
	@promise setMinExpire : Set the minimum value of the period from the point of successful bidding that the bidder can take the asset (specified by the number of blocks)
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@int minExpire : The minimum value of the period from the point of successful bidding that the bidder can take the asset (specified by the number of blocks)

#### example
```javascript
app.setMinExpire('0xasdf...', 1, 8192);
```
<br>

###  SimAsset.prototype.defineMeta (secret, classId, key, secret, keep)
	@promise defineMeta : Define the meta information to use within the asset class you created
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@string key : Key of the meta information
	@bool private : Whether non-owner can view the contents of meta information
	@bool keep : Whether to inherit meta information when asset ownership transfers

#### example
```javascript
app.defineMeta('0xasdf...', 1, 'BTC_ADDRESS', true, false);
```
<br>


###  SimAsset.prototype.acceptToChangeAdmin (secret, classId, newAdmin)
	@promise acceptToChangeAdmin : Nominate a new administrator for the asset class you created
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@string newAdmin : New administrator of the asset class

#### example
```javascript
app.acceptToChangeAdmin('0xasdf...', 1, '0xqwer...');
```
<br>


### SimAsset.prototype.changeAdmin (secret, classId)
	@promise changeAdmin : Confirm change of administrator of asset class by new administrator
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 

#### example
```javascript
app.acceptToChangeAdmin('0xasdf...', 1);
```

<br>

---

<br>

## Managing_assets

### SimAsset.prototype.assignMeta (secret, classId, serial, key, fragment, value)
	@promise assignMeta : Associate meta information with assets
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@int serial : Serial number of asset in the asset class 
	@string key : Key of the meta information
	@int fragment : Identifier in the same meta information key (This allows you to assign multiple values to the same key)
	@string value : Value of the meta information

#### example
```javascript
app.assignMeta('0xasdf...', 1, 1, 'BTC_ADDRESS', 0, '1FA27H8...');
```
<br>

### SimAsset.prototype.buyAtAsk (secret, classId, serial, newAskPrice)
	@promise buyAtAsk : Purchase assets at initial price or price suggested by old owner
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@int serial : Serial number of asset in the asset class 
	@int newAskPrice : New selling price (Specify 0 to make purchase impossible) 

#### example
```javascript
app.buyAtAsk('0xasdf...', 1, 1, 10e+18);
```
<br>

### SimAsset.prototype.setAsk (secret, classId, serial, newAskPrice)
	@promise setAsk : Set the ask price of the asset (Specify 0 to make purchase impossible) 
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@int serial : Serial number of asset in the asset class 
	@int newAskPrice : New ask price of the asset (Specify 0 to make purchase impossible) 

#### example
```javascript
app.setAsk('0xasdf...', 1, 1, 10e+18);
```
<br>

### SimAsset.prototype.bid (secret, classId, serial, bidPrice)
	@promise bid : Bid to purchase assets at prices lower than the offer price
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@int serial : Serial number of asset in the asset class 
	@int bidPrice : Bid price

#### example
```javascript
app.bid('0xasdf...', 1, 1, 10e+17);
```
<br>

### SimAsset.prototype.accept (secret, classId, serial, bidPrice, bidder, expire)
	@promise accept : Allow confirmed bidder to purchase the asset
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@int serial : Serial number of asset in the asset class 
	@int bidPrice : Bid price that bidder that the asset owner choose
	@string bidder : Bidder that the asset owner choose
	@int expire : Period from the point of successful bidding that the bidder can take the asset (specified by the number of blocks) 

#### example
```javascript
app.accept('0xasdf...', 1, 1, 10e+17, '0xqwer...', 4096);
```
<br>

### SimAsset.prototype.buyAfterAccept (secret, classId, serial, newAskPrice)
	@promise buyAfterAccept : Purchases the asset by successful bidder
	@string secret : Transaction sender's private key
	@int classId : Asset class identifier 
	@int serial : Serial number of asset in the asset class 
	@int newAskPrice : New selling price (Specify 0 to make purchase impossible) 

#### example
```javascript
app.buyAfterAccept('0xasdf...', 1, 1, 10e+18,);
```
<br>

---

<br>

## Obtaining_class_informations

### SimAsset.prototype.getClassId (name)
	@int getClassId : Get asset class identifier by asset class name
	@string name : Asset class identifier by name

#### example
```javascript
const classId = app.getClassId('MyAssetClass');
```
<br>

### SimAsset.prototype.getWholeClassIds()
	@array[int] getWholeClassId : Get all asset class identifiers

#### example
```javascript
const classIds = app.getWholeClassId();
```
<br>

### SimAsset.prototype.getNameByClassId (classId)
	@string getNameByClassId : Get asset class name by asset class identifier
	@int classId : Asset class identifier 

#### example
```javascript
const className = app.getNameByClassId(classId);
```
<br>

### SimAsset.prototype.getAdminByClassId (classId)
	@string getAdminByClassId : Get administrator of asset class by asset class identifier
	@int classId : Asset class identifier 

#### example
```javascript
const admin = app.getAdminByClassId(classId);
```
<br>

### SimAsset.prototype.getDefaultPriceByClassId (classId)
	@int getDefaultPriceByClassId : Get initial price of asset in asset class by asset class identifier
	@int classId : Asset class identifier 

#### example
```javascript
const initPrice = app.getDefaultPriceByClassId(classId);
```
<br>

### SimAsset.prototype.getMinTransferByClassId (classId)
	@int getMinTransferByClassId : Get minimum amount of transfer in asset class by asset class identifier
	@int classId : Asset class identifier  

#### example
```javascript
const minTransfer = app.getMinTransferByClassId(classId);
```
<br>

### SimAsset.prototype.getMaxTransferByClassId (classId)
	@int getMaxTransferByClassId : Get maximum amount of transfer in asset class by asset class identifier
	@int classId : Asset class identifier  

#### example
```javascript
const maxTransfer = app.getMaxTransferByClassId(classId);
```
<br>

### SimAsset.prototype.getFeeRateByClassId (classId)
	@int getFeeRateByClassId : Get maximum amount of transfer in asset class by asset class identifier
	@int classId : Asset class identifier  

#### example
```javascript
const feeRate = app.getFeeRateByClassId(classId);
```
<br>

### SimAsset.prototype.getMinExpireByClassId (classId)
	@int getMinExpireByClassId : Get the minimum value of the period from the point of successful biddtake the asset
	@int classId : Asset class identifier  

#### example
```javascript
const minExpire = app.getMinExpireByClassId(classId);
```
<br>

### SimAsset.prototype.getAssetTotalByClassId (classId)
	@int getAssetTotalByClassId : Get the total number of assets acquired in the asset class
	@int classId : Asset class identifier 

#### example
```javascript
const total = app.getAssetTotalByClassId(classId);
```
<br>

---

<br>

## Obtaining_asset_informations

### SimAsset.prototype.getAssetId (classId,serial)
	@int getAssetId : Get asset identifier by class identifier and serial number
	@int classId : Asset class identifier 
	@int serial : Serial number of asset in the asset class 

#### example
```javascript
const id = app.getAssetId(1,1);
```
<br>

### SimAsset.prototype.getWholeAssetIds (classId)
	@array[int] getWholeAssetIds : Get all asset identifiers by within the asset class
	@int classId : Asset class identifier 

#### example
```javascript
const ids = app.getWholeAssetIds(1);
```
<br>

### SimAsset.prototype.getLastByAssetId (assetId)
	@int getLastByAssetId : Get the previous contract price by asset identifier
	@int assetId : Asset identifier 

#### example
```javascript
const lastPrice = app.getLastByAssetId(1);
```
<br>

### SimAsset.prototype.getAskByAssetId (assetId)
	@int getAskByAssetId : Get the ask price by asset identifier
	@int assetId : Asset identifier 

#### example
```javascript
const ask = app.getAskByAssetId(1);
```
<br>

### SimAsset.prototype.getBidByAssetId (assetId)
	@int getBidByAssetId : Get highest bid price by asset identifier
	@int assetId : Asset identifier 

#### example
```javascript
const bid = app.getBidByAssetId(1);
```
<br>

### SimAsset.prototype.getOwnerByAssetId (assetId)
	@string getOwnerByAssetId : Get current owner by asset identifier
	@int assetId : Asset identifier 

#### example
```javascript
const owner = app.getOwnerByAssetId(1);
```
<br>


### SimAsset.prototype.getBidderByAssetId (assetId)
	@string getBidderByAssetId : Get highest bidder by asset identifier
	@int assetId : Asset identifier 

#### example
```javascript
const bidder = app.getBidderByAssetId(1);
```
<br>

### SimAsset.prototype.getAcceptedByAssetId (assetId)
	@bool getAcceptedByAssetId : Get whether or not it has been bid successfully by asset identifier
	@int assetId : Asset identifier 

#### example
```javascript
if(!app.getAcceptedByAssetId(1)){
    ...
}
```
<br>


### SimAsset.prototype.getExpireByAssetId (assetId)
	@int getExpireByAssetId : Get transfer deadline (block number) of the asset after it makes a successful bid 
	@int assetId : Asset identifier 

#### example
```javascript
const expire = app.getExpireByAssetId(1);
```

<br>

---

<br>

## Obtaining_attributes_of_meta_definitions


### SimAsset.prototype.getMetaDefinitionPrivate (classId,key)
	@bool getMetaDefinitionPrivate : Get whether meta information is disclosed or not
	@int classId : Asset class identifier 
	@string key : Key of the meta information

#### example
```javascript
if(app.getMetaDefinitionPrivate(1,'BTC_ADDRESS')){
    ...
}
```
<br>

### SimAsset.prototype.getMetaDefinitionKeep (classId,key)
	@bool getMetaDefinitionKeep : Get whether or not meta information is inherited when the ownership of the asset transferd
	@int classId : Asset class identifier
	@string key : Key of the meta information

#### example
```javascript
if(app.getMetaDefinitionKeep(1,'BTC_ADDRESS')){
    ...
}
```
<br>

---

<br>

## Obtaining_meta_informations

### SimAsset.prototype.getMetaValue (assetId,key,fragment)
	@int getMetaValue : Get value of meta information
	@int assetId : Asset identifier
	@string key : Key of the meta information
	@int fragment : Identifier in the same meta information key (This allows you to assign multiple values to the same key)

#### example
```javascript
const btcAddress = app.getMetaValue(1,'BTC_ADDRESS',0);
```

<br>

---

<br>

> ## Contributing

### Step 1

- **Option 1**
    - 🍴 Fork this repo!

- **Option 2**
    - 👯 Clone this repo to your local machine using `https://github.com/snst-lab/SimAsset.git`

### Step 2

- **HACK AWAY!** 🔨🔨🔨

### Step 3

- 🔃 Create a new pull request using <a href="https://github.com/snst-lab/SimAsset/compare/" target="_blank">`https://github.com/snst-lab/SimAsset/compare/`</a>

<br>

---

<br>


> ## Licence
[LGPL](https://www.gnu.org/licenses/lgpl-3.0.html) 

<br>

> ## Developer
[TANUSUKE](https://pragma-curry.com/)  