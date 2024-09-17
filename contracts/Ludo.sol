// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Ludo {
    uint gameCount;
    uint playerCount;
    uint maxPlayers = 4;
    struct LudoGame {
        uint gameId;
        address[] players;
        uint noOfPlayers;
        bool isCompleted;
        address winner;
    }

    struct Player {
        string name;
        uint playerId;
        address playerAddress;
        bool isWinner;
    }

    LudoGame[] allGames;
    // a mapping to check if an address is a player in a particular game
    mapping (address => mapping (uint => bool)) isPlayer;
    // check the turn of a player in the game
    mapping (address => mapping (uint => bool)) isCurrentlyPlaying;

    mapping (uint => LudoGame) game;
    mapping (uint => Player) player;

    event GameCreated();
    event PlayerAdded();

    function createGame(uint _playerCount) external {
        require(msg.sender != address(0), "invalid caller");
        require(_playerCount <= 4, "max players exceeded");
        uint count = gameCount + 1;
        LudoGame memory newGame = game[count];
        newGame.gameId = count;
        newGame.noOfPlayers = _playerCount;

        allGames.push(newGame);
        gameCount = count;

        emit GameCreated();
    }

    function addPlayer(string memory _name, uint _gameId, address _playerAddy) external {
        require(msg.sender != address(0), "invalid caller");
        LudoGame storage targetGame = game[_gameId];
        require(targetGame.gameId != 0, "invalid game ID");
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
}