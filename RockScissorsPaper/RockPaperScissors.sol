// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    enum Move { None, Rock, Paper, Scissors }
    enum GameState { Created, Joined, Revealed, Finished }

    struct Game {
        address player1;
        address player2;
        bytes32 player1Commit;
        bytes32 player2Commit;
        Move player1Move;
        Move player2Move;
        GameState state;
        uint256 bet;
    }

    mapping(uint256 => Game) public games;
    uint256 public gameIdCounter;

    event GameCreated(uint256 gameId, address player1, uint256 bet);
    event PlayerJoined(uint256 gameId, address player2);
    event MovesRevealed(uint256 gameId, Move player1Move, Move player2Move);
    event GameFinished(uint256 gameId, address winner);

    function createGame(bytes32 commit) external payable returns (uint256) {
        require(msg.value > 0, "Bet must be greater than 0");
        gameIdCounter++;
        games[gameIdCounter] = Game({
            player1: msg.sender,
            player2: address(0),
            player1Commit: commit,
            player2Commit: 0,
            player1Move: Move.None,
            player2Move: Move.None,
            state: GameState.Created,
            bet: msg.value
        });
        emit GameCreated(gameIdCounter, msg.sender, msg.value);
        return gameIdCounter;
    }

    function joinGame(uint256 gameId, bytes32 commit) external payable {
        Game storage game = games[gameId];
        require(game.state == GameState.Created, "Game not available");
        require(msg.value == game.bet, "Bet must match");
        require(game.player1 != msg.sender, "Cannot join your own game");

        game.player2 = msg.sender;
        game.player2Commit = commit;
        game.state = GameState.Joined;
        emit PlayerJoined(gameId, msg.sender);
    }

    function revealMove(uint256 gameId, Move move, string memory secret) external {
        Game storage game = games[gameId];
        require(game.state == GameState.Joined, "Game not ready for reveal");
        require(move != Move.None, "Invalid move");
        bytes32 commit = keccak256(abi.encodePacked(move, secret));

        if (msg.sender == game.player1) {
            require(commit == game.player1Commit, "Invalid reveal");
            game.player1Move = move;
        } else if (msg.sender == game.player2) {
            require(commit == game.player2Commit, "Invalid reveal");
            game.player2Move = move;
        } else {
            revert("Not a player");
        }

        if (game.player1Move != Move.None && game.player2Move != Move.None) {
            game.state = GameState.Revealed;
            determineWinner(gameId);
        }
    }

    function determineWinner(uint256 gameId) internal {
        Game storage game = games[gameId];
        require(game.state == GameState.Revealed, "Moves not revealed yet");

        address winner = address(0);
        if (game.player1Move == game.player2Move) {
            payable(game.player1).transfer(game.bet);
            payable(game.player2).transfer(game.bet);
        } else if (
            (game.player1Move == Move.Rock && game.player2Move == Move.Scissors) ||
            (game.player1Move == Move.Paper && game.player2Move == Move.Rock) ||
            (game.player1Move == Move.Scissors && game.player2Move == Move.Paper)
        ) {
            winner = game.player1;
        } else {
            winner = game.player2;
        }

        if (winner != address(0)) {
            payable(winner).transfer(game.bet * 2);
        }

        game.state = GameState.Finished;
        emit MovesRevealed(gameId, game.player1Move, game.player2Move);
        emit GameFinished(gameId, winner);
    }

    // Новая функция: получить список активных игр
    function getActiveGames() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= gameIdCounter; i++) {
            if (games[i].state == GameState.Created || games[i].state == GameState.Joined) {
                activeCount++;
            }
        }

        uint256[] memory activeGames = new uint256[](activeCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= gameIdCounter; i++) {
            if (games[i].state == GameState.Created || games[i].state == GameState.Joined) {
                activeGames[index] = i;
                index++;
            }
        }
        return activeGames;
    }
}