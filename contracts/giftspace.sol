// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/ERC721.sol";
import "@openzeppelin/contracts/IERC721Receiver.sol";
import "@openzeppelin/contracts/ERC721Holder.sol";
import "@openzeppelin/contracts/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GiftSpace is ERC721, IERC721Receiver, ERC721Holder, Ownable  {

    struct Nft {
        IERC721 tokenAddress;
        uint256 tokenID;
        address owner;
    }

    struct Gift { // record a single transaction
        uint unlockTime;
        address sender;
        string message;
        address recipient;
        bool pending; // indicate whether the gift can be unwrapped or not
        bool archived; // indicate whether the gift is archived (pulled from smart contract)
    }

    struct Display { // transaction display (all the stuff needed for frontend display)
        IERC721 tokenAddress;
        uint256 tokenID;
        address sender;
        uint receivedTime;
        string message;
    }

    // Counter for token IDs
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIDs;

    mapping(uint256 => Nft) private _nfts; // all the nfts on smart contract
    mapping(uint256 => Gift) private _gifts; // all the transactions that has been made

    string private _baseTokenURI;
    uint private _presentPrice;

    // Events
    event PresentSent(uint256 tokenId);
    event PresentUnwrapped(address tokenAddress, uint256 tokenId, string message);

    constructor(string memory baseTokenURI, uint presentPrice) ERC721("GiftSpace", "GIFTS") {
        setBaseTokenURI(baseTokenURI);
        setPresentPrice(presentPrice);
    }

    // get all the nfts of the user address that are not pending or archived
    function getCurrentNfts() public view returns {Display[]}{
        Display[] userNfts;
        for (uint i = 0; i < _nfts.length; i++) {
            Nft nft = _nfts[i];
            Gift gift = _gifts[i];
            if (msg.sender == nft.owner){
                if (!gift.pending && !gift.archived){
                    userNfts.push(Display(gift.tokenAddress, nft.tokenID, gift.sender, nft.unlockTime, gift.message));
                }
            }
        }
        return userNfts;
    }


    // get all the nfts that are being sent to this user
    function getPendingNfts() public view returns {Display[]}{
        Display[] userNfts;
        for (uint i = 0; i < _nfts.length; i++) {
            Nft nft = _nfts[i];
            Gift gift = _gifts[i];
            if (msg.sender == gift.recipient){
                if (gift.pending){
                    userNfts.push(Display(gift.tokenAddress, nft.tokenID, gift.sender, nft.unlockTime, gift.message));
                }
            }
        }
        return userNfts;
    }

    // get all the nfts that the user received and pulled
    function getArchivedNfts() public view returns {Display[]}{
        Display[] userNfts;
        for (uint i = 0; i < _nfts.length; i++) {
            Nft nft = _nfts[i];
            Gift gift = _gifts[i];
            if (msg.sender == nft.owner){
                if (gift.archived){
                    userNfts.push(Display(gift.tokenAddress, nft.tokenID, gift.sender, nft.unlockTime, gift.message));
                }
            }
        }
        return userNfts;
    }

    function wrapGift(IERC721 giftedTokenAddress, uint256 giftedTokenId, string memory message, address recipient, uint256 time){
        Nft nft = new Nft(giftedTokenAddress, giftedTokenId, msg.sender, true); //make an nft type object
        Gift gift = new Gift(time, msg.sender, message, recipient, true, false); //make a gift type object with pending = true
        //giftedTokenAddress.safeTransferFrom(msg.sender, address(this), giftedTokenId); //nft transfer
        _nfts[_tokenIDs] = nft; //gets stored in list of all nfts on smart contract
        _gifts[_tokenIDs] = gift; //gets stored in list of all transactions on smart contract
        _owned_nft[present] = msg.sender;
        //_safeMint(recipient, tokenID);
        _tokenIDs.increment(); 
    }
    
    function unwrap(uint256 tokenID) public {
        require(_exists(tokenID), "Present does not exist"); 
        Gift memory gift = _gifts[tokenID];
        require(gift.pending, "Present has already been unwrapped");
        require(gift.recipient == msg.sender, "This isn't your present buddy");
        require(block.timestamp >= gift.unlockTime, "Not time yet!");
        _nfts[tokenID].owner = msg.sender; // change ownership on smart contract
        _gifts[tokenID].pending = false; // no longer pending since unwrapped

        emit PresentUnwrapped(address(present.tokenAddress), present.tokenID, present.message);
    }

    function pull(uint tokenID) public{
        require(_exists(tokenID), "Present does not exist");
        Gift memory gift = _gifts[tokenID];
        require(!gift.pending, "Present has not been unwrapped yet");
        require(gift.recipient == msg.sender, "This isn't your present buddy");
        require(!gift.archived, "Present has already been pulled");
        _gifts[tokenID].archived = true // archiving the transaction
        // present.tokenAddress.safeTransferFrom(address(this), present.recipient, present.tokenID);
    }

     /**
     * @dev Main minting/ wrapping function.
     */
    
    

    // function sendGift(IERC721 giftedTokenAddress, uint256 giftedTokenId, string memory message, address recipient) public payable {
    //     // Can only send presents before or on christmas day
    //     require(block.timestamp < _unixChristmas + 86400, "Christmas is over, wait till next year");
        
    //     uint mintPrice = isOnNiceList() ? 0 : _presentPrice;
    //     require(msg.value == mintPrice, "Incorrect ETH sent");

    //     // We add 1 so that IDs start from 1 and not 0.
    //     uint256 tokenID = _tokenIDs.current() + 1;
    //     giftedTokenAddress.safeTransferFrom(msg.sender, address(this), giftedTokenId);
    //     _presents[tokenID] = Present(giftedTokenAddress, giftedTokenId, message, recipient);
    //     _safeMint(recipient, tokenID);
    //     _tokenIDs.increment();

    //     emit PresentSent(tokenID);
    // }

    function getPresentPrice() public view returns (uint) {
        return _presentPrice;
    }

    // onlyOwner ---------------------------

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    } 

    // function setUnixChristmas(uint unixChristmas) public onlyOwner {
    //     _unixChristmas = unixChristmas;
    // } 

    function setPresentPrice(uint presentPrice) public onlyOwner {
        _presentPrice = presentPrice;
    } 

    function withdraw(address withdrawAddress) public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "Balance is 0");
        payable(withdrawAddress).transfer(address(this).balance);
    }

    // internal overrides ---------------------------

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        // If token is being transferred and not minted or burned
        if (from != to && from != address(0) && to != address(0)) {
            _presents[tokenId].recipient = to;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _baseTokenURI;
    }

}