// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { AccessControlledV8 } from "@venusprotocol/governance-contracts/contracts/Governance/AccessControlledV8.sol";

import { ensureNonzeroAddress } from "../Utils/Validators.sol";
import { IXVSVault } from "../Interfaces/IXVSVault.sol";

contract XVSVaultTreasury is AccessControlledV8 {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice The xvs token address
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable xvsAddress;

    /// @notice The xvsvault address
    address public xvsVault;

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[48] private __gap;

    /// @notice Emitted when XVS vault address is updated
    event XVSVaultUpdated(address indexed oldXVSVault, address indexed newXVSVault);

    /// @notice Emitted when funds transferred to XVSStore address
    event FundsTransferredToXVSStore(address indexed xvsStore, uint256 amountMantissa);

    /// @notice Thrown when given input amount is zero
    error InsufficientBalance();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address xvsAddress_) {
        ensureNonzeroAddress(xvsAddress_);
        xvsAddress = xvsAddress_;

        // Note that the contract is upgradeable. Use initialize() or reinitializers
        // to set the state variables.
        _disableInitializers();
    }

    /// @dev XVS vault setter
    /// @param xvsVault_ Address of the XVS vault
    function setXVSVault(address xvsVault_) external onlyOwner {
        _setXVSVault(xvsVault_);
    }

    function fundXVSVault(uint256 amountMantissa) external {
        _checkAccessAllowed("fundXVSVault(amountMantissa)");

        uint256 balance = IERC20Upgradeable(xvsAddress).balanceOf(address(this));

        if (balance < amountMantissa) {
            revert InsufficientBalance();
        }

        address xvsStore = IXVSVault(xvsVault).xvsStore();
        IERC20Upgradeable(xvsAddress).safeTransfer(xvsStore, amountMantissa);

        emit FundsTransferredToXVSStore(xvsStore, amountMantissa);
    }

    /// @param accessControlManager_ Access control manager contract address
    /// @param xvsVault_ XVSVault address
    function initialize(address accessControlManager_, address xvsVault_) public virtual initializer {
        __AccessControlled_init(accessControlManager_);

        _setXVSVault(xvsVault_);
    }

    /// @dev XVS vault setter
    /// @param xvsVault_ Address of the XVS vault
    /// @custom:event XVSVaultUpdated emits on success
    /// @custom:error ZeroAddressNotAllowed is thrown when XVS vault address is zero
    function _setXVSVault(address xvsVault_) internal {
        ensureNonzeroAddress(xvsVault_);
        address oldXVSVault = xvsVault;
        xvsVault = xvsVault_;
        emit XVSVaultUpdated(oldXVSVault, xvsVault_);
    }
}
