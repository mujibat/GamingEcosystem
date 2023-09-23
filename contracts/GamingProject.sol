// SPDX-License-Identifier: MIT
interface IGamingEcosystemNFT {
    function mintNFT(address to) external;
    function burnNFT(uint256 tokenId) external;
    function transferNFT(uint256 tokenId, address from, address to) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}
pragma solidity ^0.8.19;


contract GamingEcosystem {
    address public owner;
    address public nftContractAddress;

    struct Player {
        string userName;
        uint256 balance;
        uint256 numberOfNFTs;
    }

    struct Game {
        string gameName;
        uint256 gameID;
        uint256 assetPrice;
        uint256 assetsSold;
    }

    mapping(address => Player) public players;
    mapping(uint256 => Game) public games;

    constructor(address _nftAddress) {
        owner = msg.sender;
        nftContractAddress = _nftAddress;
        players[msg.sender] = Player("Owner", 0, 0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier uniqueUserName(string memory _userName) {
        require(bytes(players[msg.sender].userName).length == 0, "User already registered");
        require(bytes(_userName).length >= 3, "Username must have at least 3 characters");
        _;
    }

    modifier gameExists(uint256 _gameID) {
        require(bytes(games[_gameID].gameName).length > 0, "Game does not exist");
        _;
    }

    function registerPlayer(string memory _userName) public {
        players[msg.sender] = Player(_userName, 1000, 0);
    }

    function createGame(string memory _gameName, uint256 _gameID) public onlyOwner {
        games[_gameID] = Game(_gameName, _gameID, 250, 0);
    }

    function removeGame(uint256 _gameID) public onlyOwner gameExists(_gameID) {
        Game storage game = games[_gameID];
        for (uint256 tokenId = 0; tokenId < game.assetsSold; tokenId++) {
            IGamingEcosystemNFT(nftContractAddress).burnNFT(tokenId);
            players[IGamingEcosystemNFT(nftContractAddress).ownerOf(tokenId)].balance += game.assetPrice;
        }
        delete games[_gameID];
    }

    function buyAsset(uint256 _gameID) public gameExists(_gameID) {
        Game storage game = games[_gameID];
        uint256 currentPrice = game.assetPrice;
        uint256 tokenId = game.assetsSold;

        require(players[msg.sender].balance >= currentPrice, "Not enough credits to buy asset");

        IGamingEcosystemNFT(nftContractAddress).mintNFT(msg.sender);
        players[msg.sender].numberOfNFTs++;
        players[msg.sender].balance -= currentPrice;

        game.assetsSold++;
        game.assetPrice = (currentPrice * 11) / 10; // Increment price by 10%

        emit AssetBought(msg.sender, _gameID, tokenId, currentPrice);
    }

    function sellAsset(uint256 _tokenID) public {
        address assetOwner = IGamingEcosystemNFT(nftContractAddress).ownerOf(_tokenID);
        Game storage game = games[_tokenID];

        require(assetOwner == msg.sender, "You don't own this asset");
        require(bytes(game.gameName).length > 0, "Game associated with this asset does not exist");

        uint256 currentPrice = game.assetPrice;
        players[msg.sender].balance += currentPrice;

        IGamingEcosystemNFT(nftContractAddress).burnNFT(_tokenID);
        players[msg.sender].numberOfNFTs--;

        emit AssetSold(msg.sender, _tokenID, currentPrice);
    }

    function transferAsset(uint256 _tokenID, address _to) public {
        address assetOwner = IGamingEcosystemNFT(nftContractAddress).ownerOf(_tokenID);
        Game storage game = games[_tokenID];

        require(assetOwner == msg.sender, "You don't own this asset");
        require(players[_to].balance >= game.assetPrice, "Recipient does not have enough credits");

        IGamingEcosystemNFT(nftContractAddress).transferNFT(_tokenID, msg.sender, _to);
        players[msg.sender].numberOfNFTs--;
        players[_to].numberOfNFTs++;
    }

    function viewProfile(address _playerAddress) public view returns (string memory, uint256, uint256) {
        Player memory player = players[_playerAddress];
        return (player.userName, player.balance, player.numberOfNFTs);
    }

    function viewAsset(uint256 _tokenID) public view returns (address, string memory, uint256) {
        address assetOwner = IGamingEcosystemNFT(nftContractAddress).ownerOf(_tokenID);
        Game memory game = games[_tokenID];
        return (assetOwner, game.gameName, game.assetPrice);
    }

    event AssetBought(address indexed buyer, uint256 gameID, uint256 tokenID, uint256 price);
    event AssetSold(address indexed seller, uint256 tokenID, uint256 price);
}
