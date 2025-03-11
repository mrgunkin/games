// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GuessTheNumber {
    address public owner;
    uint256 public constant MIN_BET = 0.01 ether;
    uint256 public totalPrizePool;

    event GamePlayed(address player, uint256 guess, uint256 number, bool won, uint256 prize);

    constructor() {
        owner = msg.sender;
    }

    function play(uint256 guess) external payable {
        require(msg.value >= MIN_BET, "Bet must be at least 0.01 ETH");
        require(guess >= 1 && guess <= 10, "Guess must be between 1 and 10");

        // Генерируем случайное число от 1 до 10
        uint256 number = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number))) % 10) + 1;

        bool won = (guess == number);
        uint256 prize = 0;

        if (won) {
            prize = msg.value * 2; // Удваиваем ставку
            require(address(this).balance >= prize, "Not enough funds in contract");
            payable(msg.sender).transfer(prize);
        } else {
            totalPrizePool += msg.value; // Добавляем ставку в призовой фонд
        }

        emit GamePlayed(msg.sender, guess, number, won, prize);
    }

    // Функция для вывода средств владельцем (опционально)
    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    // Проверка баланса контракта
    receive() external payable {}
}