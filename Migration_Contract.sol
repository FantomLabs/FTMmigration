// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.24;

// Minimal ERC20 interface required to transfer DUSK
interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

/// @title The ERC20/BEP20 DUSK migration contract
/// @author Hein Dauven
/// @notice It is assumed that another service or protocol catches the migration events and processes them accordingly
contract DUSKMigration {
    IERC20 public immutable duskToken;
    // Conversion factor between ERC20 DUSK (18 decimals) and native DUSK (9 decimals), where 10^9 DUSK wei is equivalent to 1 LUX
    uint256 constant LUX_CONVERSION_FACTOR = 10**9; 

    // Event to log the migration for reissuing on Dusk mainnet. The amount being in LUX
    event Migration(address indexed from, uint256 amount, string targetAddress);

    /**
     * @param _duskTokenAddress The address of the ERC20/BEP20 DUSK token contract.
     */
    constructor(address _duskTokenAddress) {
        duskToken = IERC20(_duskTokenAddress);
    }

    /**
     * @notice Migrates ERC20 DUSK tokens to native DUSK by transferring the tokens from the sender to this contract for locking.
     *         The function rounds the amount down to the nearest 1 LUX (10^9 DUSK wei).
     * 
     * @dev This function follows a simple check-interactions pattern to minimize reentrancy risk:
     *      1. Check: Check if the `amount` is greater than or equal to 1 LUX.
     *      2. Interaction: Transfers the specified amount of DUSK tokens to the contract and emits a `Migration` event.
     * 
     * @dev We assume that the targetAddress is a valid Moonlight key. The user will never explicitly type in the key, it will instead be provided by the UX.
     * 
     * @param amount The amount of ERC20 DUSK tokens to migrate in DUSK wei. Must be at least 1 LUX (10^9 wei).
     * @param targetAddress The native DUSK mainnet Moonlight key where the equivalent native DUSK should be reissued.
     */
    function migrate(uint256 amount, string memory targetAddress) external {
        // The minimum migration amount has to be larger or equal to the conversion factor
        require(amount >= LUX_CONVERSION_FACTOR, "Amount must be at least 1 LUX");

        // Round down the amount to the nearest multiple of 1 LUX
        uint256 roundedAmount = (amount / LUX_CONVERSION_FACTOR) * LUX_CONVERSION_FACTOR;

        // Transfer the specified amount of DUSK tokens to this contract
        duskToken.transferFrom(msg.sender, address(this), roundedAmount);

        // Adjust the amount to account for the difference in decimals between native DUSK (9 decimals) and ERC20/BEP20 DUSK (18 decimals)
        uint256 nativeAmount = roundedAmount / LUX_CONVERSION_FACTOR;

        // Emit the migration event with the value in LUX
        emit Migration(msg.sender, nativeAmount, targetAddress);
    }
}
