// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Ludo {
    uint gameCount;
    uint playerCount;
    uint maxPlayers = 2;
    struct LudoGame {
        uint gameId;
        address[] players;
        uint noOfPlayers;
        bool hasStarted;
        bool isCompleted;
        address winner;
        uint winningNumber;
    }

    struct Player {
        string name;
        uint playerId;
        address playerAddress;
        bool isWinner;
    }

    LudoGame[] public allGames;
    // a mapping to check if an address is a player in a particular game
    mapping (address => mapping (uint => bool)) isPlayer;
    // check the turn of a player in the game
    mapping (address => mapping (uint => bool)) isCurrentlyPlaying;
    mapping (address => mapping (uint => uint)) numberPlayed;

    mapping (uint => LudoGame) game;
    mapping (uint => Player) player;

    event GameCreated();
    event PlayerAdded();

    function createGame(uint _playerCount, uint _winningNumber) external {
        require(msg.sender != address(0), "invalid caller");
        require(_playerCount <= 4, "max players exceeded");
        uint count = gameCount + 1;
        LudoGame memory newGame = game[count];
        newGame.gameId = count;
        newGame.noOfPlayers = _playerCount;
        newGame.winningNumber = _winningNumber;

        allGames.push(newGame);
        gameCount = count;

        emit GameCreated();
    }

    function addPlayer(string memory _name, uint _gameId, address _playerAddy) external {
        require(msg.sender != address(0), "invalid caller");
        LudoGame storage targetGame = game[_gameId];
        // require(targetGame.gameId != 0, "invalid game ID");
        require(targetGame.noOfPlayers <= 4, "max players exceeded");
        require(!isPlayer[_playerAddy][_gameId], "player already added");
        uint count = playerCount + 1;
        Player memory newPlayer = player[count];
        newPlayer.name = _name;
        newPlayer.playerId = count;
        newPlayer.playerAddress = _playerAddy;

        targetGame.noOfPlayers += 1;
        targetGame.players.push(_playerAddy);

        playerCount = count;

        emit PlayerAdded();
    }

    function playGame(uint _gameId) external returns (uint) {
        require(msg.sender != address(0), "invalid caller");
        LudoGame storage targetGame = game[_gameId];
        require(targetGame.gameId != 0, "invalid game ID");
        require(isPlayer[msg.sender][_gameId], "not a valid player");
        if (!targetGame.hasStarted) {
            targetGame.hasStarted = true;
        }
        uint randomNo = uint(keccak256(abi.encodePacked(msg.sender, _gameId)));
        return randomNo % 10^16;
    }

}