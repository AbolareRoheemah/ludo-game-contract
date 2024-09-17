// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Ludo {
    uint gameCount;
    uint playerCount;
    uint maxPlayers = 4;

    struct LudoGame {
        uint gameId;
        address[] players;
        uint8 noOfPlayers;
        bool hasStarted;
        bool isCompleted;
        address winner;
        uint8 winningPosition;
        uint currentPlayerIndex;
    }

    struct Player {
        string name;
        uint playerId;
        address playerAddress;
        bool isWinner;
        uint8[4] tokenPositions;
        uint8 tokensHome;
    }

    LudoGame[] allGames;
    // a mapping to check if an address is a player in a particular game
    mapping (address => mapping (uint => bool)) isPlayer;
    // check the turn of a player in the game
    mapping (address => mapping (uint => bool)) isCurrentlyPlaying;
    mapping (address => mapping (uint => uint)) numberPlayed;

    mapping (uint => LudoGame) game;
    mapping (uint => Player) player;
    mapping(uint => mapping(address => Player)) players;

    event GameCreated();
    event PlayerAdded();
    event GameStarted();
    event DiceRolled();
    event TokenMoved();
    event PlayerWon(uint gameId, address winner);

    function createGame(uint8 _playerCount, uint8 _winningPosition) external {
        require(msg.sender != address(0), "invalid caller");
        require(_playerCount <= 4, "max players exceeded");
        uint count = gameCount + 1;
        // LudoGame storage newGame = game[count];
        // newGame.gameId = count;
        // newGame.noOfPlayers = _playerCount;
        // newGame.winningPosition = _winningPosition;

        game[count] = LudoGame({
            gameId: count,
            players: new address[](0),
            noOfPlayers: 0,
            hasStarted: false,
            isCompleted: false,
            winner: address(0),
            winningPosition: _winningPosition,
            currentPlayerIndex: 0
        });
        gameCount = count;
        allGames.push(game[count]);

        emit GameCreated();
    }

    function addPlayer(string memory _name, uint _gameId, address _playerAddy) external {
        require(msg.sender != address(0), "invalid caller");
        LudoGame storage targetGame = game[_gameId];
        require(targetGame.gameId != 0, "invalid game ID");
        require(!targetGame.hasStarted, "cant add player to ongoing game");
        require(targetGame.noOfPlayers <= maxPlayers, "max players exceeded");
        require(!isPlayer[_playerAddy][_gameId], "player already added");

        uint count = playerCount + 1;
        // Player storage newPlayer = player[count];
        // newPlayer.name = _name;
        // newPlayer.playerId = count;
        // newPlayer.playerAddress = _playerAddy;
        // newPlayer.tokenPositions = [0,0,0,0];
        players[_gameId][msg.sender] = Player({
            name: _name,
            tokenPositions: [0, 0, 0, 0],
            tokensHome: 0,
            isWinner: false,
            playerAddress: _playerAddy,
            playerId: count
        });

        targetGame.players.push(_playerAddy);
        targetGame.noOfPlayers++;
        isPlayer[_playerAddy][_gameId] = true;

        playerCount = count;

        emit PlayerAdded();

        if (targetGame.noOfPlayers == 2) {
            targetGame.hasStarted = true;
            isCurrentlyPlaying[targetGame.players[0]][_gameId] = true;
            emit GameStarted();
        }
    }

    function playGame(uint _gameId) external view returns (uint rand) {
        require(msg.sender != address(0), "invalid caller");
        LudoGame storage targetGame = game[_gameId];
        require(targetGame.gameId != 0, "invalid game ID");
        require(isCurrentlyPlaying[msg.sender][_gameId], "not your turn");
        require(isPlayer[msg.sender][_gameId], "not a valid player");
        require(targetGame.hasStarted, "game hasnt started");
        require(!targetGame.isCompleted, "game has ended");
        rand = (uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, gameCount))) % 6) + 1;
        // emit DiceRolled();

        // return rand;
    }

    function moveToken(uint _gameId, uint8 _tokenIndex, uint8 _spaces) external {
        require(isPlayer[msg.sender][_gameId], "not a player in this game");
        require(isCurrentlyPlaying[msg.sender][_gameId], "not your turn");
        LudoGame storage targetGame = game[_gameId];
        require(targetGame.hasStarted, "game has not started");
        require(!targetGame.isCompleted, "game is already completed");
        require(_tokenIndex < 4, "invalid token index");

        Player storage currentPlayer = players[_gameId][msg.sender]; // player isnt a 2D mapping but iys treated as such here
        uint8 currentPos = currentPlayer.tokenPositions[_tokenIndex];
        uint8 newPos = currentPos + _spaces;

        if (newPos > targetGame.winningPosition) {
            newPos = targetGame.winningPosition - (newPos - targetGame.winningPosition);
        }

        if (newPos == targetGame.winningPosition) {
            currentPlayer.tokensHome++;
            newPos = 0; // Reset token position
        }

        currentPlayer.tokenPositions[_tokenIndex] = newPos;

        emit TokenMoved();

        if (currentPlayer.tokensHome == 4) {
            targetGame.isCompleted = true;
            targetGame.winner = msg.sender;
            currentPlayer.isWinner = true;
            emit PlayerWon(_gameId, msg.sender);
        } else {
            _nextTurn(_gameId);
        }
    }
    function _nextTurn(uint _gameId) private {
        LudoGame storage targetGame = game[_gameId];
        isCurrentlyPlaying[targetGame.players[targetGame.currentPlayerIndex]][_gameId] = false;
        targetGame.currentPlayerIndex = (targetGame.currentPlayerIndex + 1) % maxPlayers;
        isCurrentlyPlaying[targetGame.players[targetGame.currentPlayerIndex]][_gameId] = true;
    }

    function getPlayerState(uint _gameId, address _player) external view returns (
        string memory name,
        uint8[4] memory tokenPositions,
        uint8 tokensHome,
        bool isWinner
    ) {
        require(isPlayer[_player][_gameId], "not a player in this game");
        Player storage playerData = players[_gameId][_player];

        return (
            playerData.name,
            playerData.tokenPositions,
            playerData.tokensHome,
            playerData.isWinner
        );
    }

}