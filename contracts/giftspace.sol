// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";
import "./utils/Counters.sol";

contract GiftSpace is ERC721, IERC721Receiver, ERC721Holder, Ownable  {

    struct Nft {
        IERC721 tokenAddress;
        uint256 tokenID;
        address owner;
    }

    struct Gift { // record a single transaction
        Nft nft;
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

    mapping(uint256 => Gift) private _gifts; // all the transactions that have been made
    mapping(address => uint256) private _num_current_gifts;
    mapping(address => uint256) private _num_pending_gifts;
    mapping(address => uint256) private _num_archived_gifts;

    //string private _baseTokenURI;
    //uint private _presentPrice;

    // Events
    event GiftSent(uint256 tokenId);
    event GiftUnwrapped(address tokenAddress, uint256 tokenId, string message);

    constructor() ERC721("GiftSpace", "GIFTS") {
        
    }

    // get all the nfts of the user address that are not pending or archived
    function getCurrentNfts() public view returns (Display[] memory) {
        Display[] memory userNfts = new Display[](_num_current_gifts[msg.sender]);
        uint idx = 0;
        for (uint i = 0; i < _tokenIDs.current() + 1; i++) {
            Gift memory gift = _gifts[i];
            if (msg.sender == gift.nft.owner){
                if (!gift.pending && !gift.archived){
                    userNfts[idx] = Display(gift.nft.tokenAddress, gift.nft.tokenID, gift.sender, gift.unlockTime, gift.message);
                    idx += 1;
                }
            }
        }
        return userNfts;
    }


    // get all the nfts that are being sent to this user
    function getPendingNfts() public view returns (Display[] memory) {
        Display[] memory userNfts = new Display[](_num_pending_gifts[msg.sender]);
        uint idx = 0;
        for (uint i = 0; i < _tokenIDs.current() + 1; i++) {
            Gift memory gift = _gifts[i];
            if (msg.sender == gift.recipient){
                if (gift.pending){
                    userNfts[idx] = Display(gift.nft.tokenAddress, gift.nft.tokenID, gift.sender, gift.unlockTime, gift.message);
                    idx += 1;
                }
            }
        }
        return userNfts;
    }

    // get all the nfts that the user received and pulled
    function getArchivedNfts() public view returns (Display[] memory) {
        Display[] memory userNfts = new Display[](_num_archived_gifts[msg.sender]);
        uint idx = 0;
        for (uint i = 0; i < _tokenIDs.current() + 1; i++) {
            Gift memory gift = _gifts[i];
            if (msg.sender == gift.nft.owner){
                if (gift.archived){
                    userNfts[idx] = Display(gift.nft.tokenAddress, gift.nft.tokenID, gift.sender, gift.unlockTime, gift.message);
                    idx += 1;
                }
            }
        }
        return userNfts;
    }

    function wrapGift(IERC721 giftedTokenAddress, uint256 giftedTokenId, string memory message, address recipient, uint256 time) public {
        Nft memory nft = Nft(giftedTokenAddress, giftedTokenId, msg.sender); // make an nft type object
        Gift memory gift = Gift(nft, time, msg.sender, message, recipient, true, false); // make a gift type object with pending = true
        //giftedTokenAddress.safeTransferFrom(msg.sender, address(this), giftedTokenId); //nft transfer
        _gifts[_tokenIDs.current()] = gift; // gets stored in list of all transactions on smart contract
        //_safeMint(recipient, tokenID);
        _tokenIDs.increment();
        _num_pending_gifts[recipient] += 1;
    }
    
    function unwrap(uint256 tokenID) public {
        require(_exists(tokenID), "Gift does not exist");
        Gift memory gift = _gifts[tokenID];
        require(gift.pending, "Gift has already been unwrapped");
        require(gift.recipient == msg.sender, "This isn't your gift buddy");
        require(block.timestamp >= gift.unlockTime, "Not time yet!");
        gift.nft.owner = msg.sender; // change ownership on smart contract
        gift.pending = false; // no longer pending since unwrapped

        _num_pending_gifts[msg.sender] -= 1;
        _num_current_gifts[msg.sender] += 1;

        emit GiftUnwrapped(address(gift.nft.tokenAddress), gift.nft.tokenID, gift.message);
    }

    function pull(uint tokenID) public{
        require(_exists(tokenID), "Gift does not exist");
        Gift memory gift = _gifts[tokenID];
        require(!gift.pending, "Gift has not been unwrapped yet");
        require(gift.recipient == msg.sender, "This isn't your gift buddy");
        require(!gift.archived, "Gift has already been pulled");
        gift.archived = true; // archiving the transaction
        gift.nft.tokenAddress.safeTransferFrom(address(this), gift.recipient, gift.nft.tokenID);

        _num_current_gifts[msg.sender] -= 1;
        _num_archived_gifts[msg.sender] += 1;
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

    // function getGiftPrice() public view returns (uint) {
    //     return _giftPrice;
    // }

    // onlyOwner ---------------------------

    // function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
    //     _baseTokenURI = baseTokenURI;
    // } 

    // function setUnixChristmas(uint unixChristmas) public onlyOwner {
    //     _unixChristmas = unixChristmas;
    // } 

    // function setGiftPrice(uint giftPrice) public onlyOwner {
    //     _giftPrice = giftPrice;
    // }

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
            _gifts[tokenId].recipient = to;
        }
    }

    

}