// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MultiSend
 * @dev Distributes Ether equally among multiple addresses in a single transaction.
 * @notice Sending value is split evenly across all provided recipients. Any
 * remainder (due to integer division) stays in the contract and can be
 * withdrawn by the owner via `withdrawDust`.
 */
contract MultiSend {

    // ------------------------------------------------------------------
    // State Variables
    // ------------------------------------------------------------------

    // Contract deployer, allowed to recover any leftover "dust" wei
    // that cannot be evenly divided among recipients.
    address public owner;

    // ------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------

    // Emitted once per successful distribution, summarizing the batch.
    event FundsDistributed(
        address indexed sender,
        uint256 totalAmount,
        uint256 recipientCount,
        uint256 amountPerRecipient
    );

    // Emitted for each individual transfer, useful for off-chain tracking
    // and auditing in block explorers.
    event TransferSucceeded(address indexed recipient, uint256 amount);

    // ------------------------------------------------------------------
    // Modifiers
    // ------------------------------------------------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "MultiSend: caller is not the owner");
        _;
    }

    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------

    constructor() {
        // The deployer becomes the owner, used only for dust recovery.
        owner = msg.sender;
    }

    // ------------------------------------------------------------------
    // Core Function: multiSend
    // ------------------------------------------------------------------

    /**
     * @notice Splits msg.value equally among `recipients` and sends it.
     * @param recipients Array of addresses to receive funds.
     */
    function multiSend(address[] calldata recipients) external payable {
        // --- Input validation section ---

        // The array must contain at least one address; otherwise there's
        // nothing meaningful to distribute.
        require(recipients.length > 0, "MultiSend: recipients array is empty");

        // The caller must actually send Ether with the transaction.
        require(msg.value > 0, "MultiSend: no Ether sent");

        uint256 recipientCount = recipients.length;

        // --- Calculation section ---

        // Integer division: any remainder is intentionally left in the
        // contract (e.g., sending 10 wei to 3 addresses gives 3 wei each,
        // with 1 wei remaining). This avoids reverting on harmless
        // rounding and keeps gas costs predictable.
        uint256 amountPerRecipient = msg.value / recipientCount;

        // Guard against a degenerate case: if msg.value is smaller than
        // recipientCount, integer division produces 0 per recipient.
        // Sending 0 to every address would just waste gas, so we revert
        // with a clear, actionable error instead.
        require(
            amountPerRecipient > 0,
            "MultiSend: Ether amount too small to split among recipients"
        );

        // --- Distribution section ---

        // Loop through each address sequentially and send its share.
        // Using a `for` loop (rather than recursion) keeps gas usage
        // linear and predictable, and is the standard Solidity pattern.
        for (uint256 i = 0; i < recipientCount; i++) {
            address recipient = recipients[i];

            // Reject the zero address explicitly — sending Ether to
            // address(0) would succeed at the EVM level but the funds
            // would be permanently unrecoverable.
            require(
                recipient != address(0),
                "MultiSend: recipient is the zero address"
            );

            // Use call{value: ...} instead of transfer()/send() because:
            // 1. transfer()/send() are capped at 2300 gas, which can
            //    fail for recipients that are smart contracts/wallets
            //    with logic in their receive()/fallback() functions.
            // 2. call{value: ...} forwards all available gas (subject
            //    to the 63/64 rule) and lets us explicitly check the
            //    success boolean, giving the caller full control.
            (bool success, ) = recipient.call{value: amountPerRecipient}("");

            // Verify each transfer succeeds before continuing. If any
            // single transfer fails, the entire transaction reverts,
            // which automatically rolls back all prior transfers too
            // (atomicity is guaranteed by the EVM transaction model).
            require(
                success,
                "MultiSend: transfer to recipient failed"
            );

            // Emit a per-recipient event for transparent, granular
            // on-chain tracking.
            emit TransferSucceeded(recipient, amountPerRecipient);
        }

        // --- Summary event ---

        // Emit one summary event for the whole batch, useful for
        // dashboards/indexers that want a single entry per call.
        emit FundsDistributed(
            msg.sender,
            msg.value,
            recipientCount,
            amountPerRecipient
        );
    }

    // ------------------------------------------------------------------
    // Maintenance Function: withdrawDust
    // ------------------------------------------------------------------

    /**
     * @notice Allows the owner to withdraw any leftover wei caused by
     * integer-division remainders from past distributions.
     * @dev This contract is not designed to hold funds long-term; this
     * is purely a cleanup mechanism for unavoidable rounding remainders.
     */
    function withdrawDust() external onlyOwner {
        uint256 balance = address(this).balance;

        require(balance > 0, "MultiSend: no dust to withdraw");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "MultiSend: dust withdrawal failed");
    }

    // ------------------------------------------------------------------
    // View Helper
    // ------------------------------------------------------------------

    /**
     * @notice Returns the contract's current Ether balance (should
     * normally be 0 or only contain rounding dust).
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // ------------------------------------------------------------------
    // Safety Nets
    // ------------------------------------------------------------------

    // Reject plain Ether transfers that don't go through multiSend(),
    // so funds can never get "stuck" without a clear distribution path.
    receive() external payable {
        revert("MultiSend: send Ether via multiSend(), not direct transfer");
    }

    fallback() external payable {
        revert("MultiSend: function does not exist");
    }
}
