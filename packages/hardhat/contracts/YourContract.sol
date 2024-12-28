//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "hardhat/console.sol";

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
// import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * A smart contract that allows changing a state variable of the contract and tracking the changes
 * It also allows the owner to withdraw the Ether in the contract
 * @author BuidlGuidl
 */
contract YourContract {
    // State Variables
    address public immutable owner;

    // Constructor: Called once on contract deployment
    // Check packages/hardhat/deploy/00_deploy_your_contract.ts
    constructor(address _owner) {
        owner = _owner;
    }

    // Modifier: used to define a set of rules that must be met before or after a function is executed
    // Check the withdraw() function
    modifier isOwner() {
        // msg.sender: predefined variable that represents address of the account that called the current function
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    // Структура для описания аукциона
    struct Auction {
        uint tokenId;
        address highestBidder;
        uint highestBid;
        uint endTime;
        uint minIncrement;
        bool active;
    }

    mapping(uint => Auction) public auctions;
    uint public auctionCounter;

    mapping(address => uint[]) public userNFTs;

    // События
    event AuctionCreated(uint auctionId, uint tokenId, uint endTime, uint minIncrement);
    event NewBid(uint auctionId, address bidder, uint amount);
    event AuctionEnded(uint auctionId, address winner, uint amount);

    // Создать аукцион
    function createAuction(
        uint _tokenId,
        uint _duration,
        uint _minIncrement
    ) external {
        // Создаем аукцион
        auctionCounter++;
        auctions[auctionCounter] = Auction({
            tokenId: _tokenId,
            highestBidder: address(0),
            highestBid: 0,
            endTime: block.timestamp + _duration,
            minIncrement: _minIncrement,
            active: true
        });

        emit AuctionCreated(auctionCounter, _tokenId, block.timestamp + _duration, _minIncrement);
    }

    // Сделать ставку
    function placeBid(uint _auctionId) external payable {
        Auction storage auction = auctions[_auctionId];

        require(block.timestamp < auction.endTime, "Auction has ended");
        require(auction.active, "Auction is not active");
        require(msg.value >= auction.highestBid + auction.minIncrement, "Bid is too low");

        // Возвращаем ставку предыдущему лидеру, если он был
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        // Обновляем данные аукциона
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit NewBid(_auctionId, msg.sender, msg.value);
    }

    // Завершить аукцион
    function endAuction(uint _auctionId) external {
        Auction storage auction = auctions[_auctionId];

        require(auction.active, "Auction is not active");
        require(block.timestamp >= auction.endTime || msg.sender == owner, "Auction is still ongoing");

        auction.active = false;

        if (auction.highestBidder != address(0)) {
            // Добавляем NFT победителю в список
            userNFTs[auction.highestBidder].push(auction.tokenId);

            // Отправляем средства владельцу
            payable(owner).transfer(auction.highestBid);
        } else {
            // NFT остается у владельца, если не было ставок
        }

        emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid);
    }

    // Получить список NFT пользователя
    function getUserNFTs(address _user) external view returns (uint[] memory) {
        return userNFTs[_user];
    }
}
