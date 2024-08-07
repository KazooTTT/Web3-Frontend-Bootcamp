// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./DeJeuneNFT.sol";
import "./OpenBuildToken.sol";
import "./interface/INFTMarket.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is INFTMarket, ReentrancyGuard {
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        bool isActivate;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    IERC20 public paymentToken;

    constructor(address _paymentToken){ 
        paymentToken = IERC20(_paymentToken);
    }

    function listNFT(address _nftContract, uint256 _tokenId, uint256 _price) external {
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "Not the owner of the NFT");
        require(nft.isApprovedForAll(msg.sender, address(this)), "Contract not approved");
        listings[_nftContract][_tokenId] = Listing(msg.sender, _nftContract, _tokenId, _price, true);

        emit NFTListed(msg.sender, _nftContract, _tokenId, _price);
    }

    function buyNFT(address _nftContract, uint256 _tokenId) external nonReentrant{
        Listing storage listing = listings[_nftContract][_tokenId];
        require(listing.isActivate, "NFT not listed for sale");

        IERC721 nft = IERC721(_nftContract);
        require(paymentToken.transferFrom(msg.sender, listing.seller, listing.price), "payment failed");
        nft.safeTransferFrom(listing.seller, msg.sender, _tokenId);
        listing.isActivate = false;

        emit NFTPurchased(msg.sender, _nftContract, _tokenId, listing.price);

    }
}
