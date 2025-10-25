// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RWA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RWAFactory
 * @dev Factory to deploy `RWA` contracts and manage whitelist-based minting.
 *
 * The factory:
 * - deploys new `RWA` instances
 * - manages a whitelist signer for signature-based minting
 * - verifies signatures and mints NFTs on behalf of whitelisted users
 */
contract RWAFactory is Ownable {
    address[] public deployedRWAs;
    
    // TODO: Add whitelist signer and signature verification later
    // address public whitelistSigner;
    
    // Track which addresses have already minted (per RWA contract)
    // rwaAddress => userAddress => hasMinted
    mapping(address => mapping(address => bool)) public hasMinted;

    event RWADeployed(address indexed rwaAddress, address indexed owner);
    event MintedWithSignature(address indexed rwaAddress, address indexed user, uint256 tokenId);

    /// @notice Deploy an initial RWA contract when the factory is deployed.
    /// @param initialOwner The address that should become the owner of the initially deployed RWA
    constructor(address initialOwner) Ownable(msg.sender) {
        // Deploy RWA; the factory contract will be the temporary owner.
        RWA rwa = new RWA();
        // Transfer ownership to the desired initial owner.
        rwa.transferOwnership(initialOwner);
        deployedRWAs.push(address(rwa));
        emit RWADeployed(address(rwa), initialOwner);
    }

    /// @notice Set the whitelist signer who will sign mint approvals
    /// @dev only factory owner can set this
    /// TODO: Implement this function later with signature verification
    /*
    function setWhitelistSigner(address signer) external onlyOwner {
        whitelistSigner = signer;
        emit WhitelistSignerSet(signer);
    }
    */

    /// @notice Deploy a new RWA contract and transfer ownership to `initialOwner`
    /// @param initialOwner The address that should become the owner of the new RWA
    /// @return The address of the newly deployed RWA contract
    function createRWA(address initialOwner) external returns (address) {
        RWA rwa = new RWA();

        // The factory (this contract) is the initial owner (RWA's constructor sets owner to deployer).
        // Transfer the ownership to the requested initialOwner.
        rwa.transferOwnership(initialOwner);

        deployedRWAs.push(address(rwa));
        emit RWADeployed(address(rwa), initialOwner);
        return address(rwa);
    }

    /// @notice Returns all deployed RWA addresses
    function getDeployedRWAs() external view returns (address[] memory) {
        return deployedRWAs;
    }

    /// @notice Mint an NFT (signature verification disabled for now)
    /// @param rwaAddress The address of the RWA contract to mint from
    /// @param uri metadata URI for the minted token
    /// @param signature ECDSA signature (currently unused, will be implemented later)
    function mintWithSignature(
        address rwaAddress,
        string memory uri,
        bytes memory signature
    ) external returns (uint256) {
        // TODO: Add signature verification later
        // For now, just check if user has already minted
        require(!hasMinted[rwaAddress][msg.sender], "Already minted from this RWA");

        // Mark as minted
        hasMinted[rwaAddress][msg.sender] = true;

        // Call safeMint on the RWA contract (factory must be owner or have minting rights)
        RWA rwa = RWA(rwaAddress);
        uint256 tokenId = rwa.safeMint(msg.sender, uri);
        
        emit MintedWithSignature(rwaAddress, msg.sender, tokenId);
        return tokenId;
    }
}
