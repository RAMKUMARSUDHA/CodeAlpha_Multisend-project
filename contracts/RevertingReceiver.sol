// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RevertingReceiver
 * @dev Test-only helper contract that always rejects incoming Ether.
 * Used to verify that MultiSend correctly reverts the entire batch
 * if any single transfer fails.
 */
contract RevertingReceiver {
    receive() external payable {
        revert("I refuse Ether");
    }
}
