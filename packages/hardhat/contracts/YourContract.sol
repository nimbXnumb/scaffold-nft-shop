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
    string public greeting = "Building Unstoppable Apps!!!";
    bool public premium = false;
    uint public totalCounter = 0;
    mapping(address => uint) public userGreetingCounter;

    // Events: a way to emit log statements from smart contract that can be listened to by external parties
    event GreetingChange(address indexed greetingSetter, string newGreeting, bool premium, uint value);

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

    /**
     * Function that allows anyone to change the state variable "greeting" of the contract and increase the counters
     *
     * @param _newGreeting (string memory) - new greeting to save on the contract
     */
    function setGreeting(string memory _newGreeting) public payable {
        // Print data to the hardhat chain console. Remove when deploying to a live network.
        console.log("Setting new greeting '%s' from %s", _newGreeting, msg.sender);

        // Change state variables
        greeting = _newGreeting;
        totalCounter += 1;
        userGreetingCounter[msg.sender] += 1;

        // msg.value: built-in global variable that represents the amount of ether sent with the transaction
        if (msg.value > 0) {
            premium = true;
        } else {
            premium = false;
        }

        // emit: keyword used to trigger an event
        emit GreetingChange(msg.sender, _newGreeting, msg.value > 0, msg.value);
    }

    /**
     * Function that allows the owner to withdraw all the Ether in the contract
     * The function can only be called by the owner of the contract as defined by the isOwner modifier
     */
    function withdraw() public isOwner {
        (bool success, ) = owner.call{ value: address(this).balance }("");
        require(success, "Failed to send Ether");
    }

    /**
     * Function that allows the contract to receive ETH
     */
    receive() external payable {}

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
