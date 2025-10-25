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
    
    // Whitelist management
    mapping(address => bool) public whitelist;
    
    // Map each whitelisted address to their pre-assigned URI
    mapping(address => string) public whitelistURIs;
    
    // Array to track all whitelisted addresses for iteration
    address[] private whitelistedAddresses;
    
    // Map address to its index in whitelistedAddresses array (1-indexed, 0 means not in array)
    mapping(address => uint256) private whitelistIndex;
    
    // TODO: Add whitelist signer and signature verification later
    // address public whitelistSigner;
    
    // Track which addresses have already minted (per RWA contract)
    // rwaAddress => userAddress => hasMinted
    mapping(address => mapping(address => bool)) public hasMinted;
    
    // Track total mints per RWA contract
    mapping(address => uint256) public mintCountPerRWA;
    
    // Track total mints by this factory
    uint256 public totalMints;

    event RWADeployed(address indexed rwaAddress, address indexed owner);
    event MintedWithSignature(address indexed rwaAddress, address indexed user, uint256 tokenId);
    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);

    /// @notice Deploy an initial RWA contract when the factory is deployed.
    /// @param initialOwner The address that should become the owner of the factory (not used for RWA ownership)
    constructor(address initialOwner) Ownable(msg.sender) {
        // Deploy RWA; the factory contract will be the owner to enable minting
        RWA rwa = new RWA();
        // Factory remains the owner so it can call safeMint
        deployedRWAs.push(address(rwa));
        emit RWADeployed(address(rwa), address(this));
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

    /// @notice Deploy a new RWA contract with factory as owner
    /// @return The address of the newly deployed RWA contract
    function createRWA() external onlyOwner returns (address) {
        RWA rwa = new RWA();

        // The factory (this contract) remains the owner so it can mint
        deployedRWAs.push(address(rwa));
        emit RWADeployed(address(rwa), address(this));
        return address(rwa);
    }

    /// @notice Returns all deployed RWA addresses
    function getDeployedRWAs() external view returns (address[] memory) {
        return deployedRWAs;
    }

    /// @notice Add an address to the whitelist with pre-assigned URI
    /// @param account The address to add to the whitelist
    /// @param uri The metadata URI pre-assigned to this address
    function addToWhitelist(address account, string memory uri) external onlyOwner {
        require(account != address(0), "Cannot add zero address");
        require(!whitelist[account], "Already in whitelist");
        require(bytes(uri).length > 0, "URI cannot be empty");
        
        whitelist[account] = true;
        whitelistURIs[account] = uri;
        
        // Add to array for iteration
        whitelistedAddresses.push(account);
        whitelistIndex[account] = whitelistedAddresses.length; // 1-indexed
        
        emit WhitelistAdded(account);
    }

    /// @notice Add multiple addresses to the whitelist with their pre-assigned URIs
    /// @param accounts Array of addresses to add to the whitelist
    /// @param uris Array of metadata URIs corresponding to each address
    function addToWhitelistBatch(address[] calldata accounts, string[] calldata uris) external onlyOwner {
        require(accounts.length == uris.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "Cannot add zero address");
            require(bytes(uris[i]).length > 0, "URI cannot be empty");
            
            if (!whitelist[accounts[i]]) {
                whitelist[accounts[i]] = true;
                whitelistURIs[accounts[i]] = uris[i];
                
                // Add to array for iteration
                whitelistedAddresses.push(accounts[i]);
                whitelistIndex[accounts[i]] = whitelistedAddresses.length; // 1-indexed
                
                emit WhitelistAdded(accounts[i]);
            }
        }
    }

    /// @notice Remove an address from the whitelist
    /// @param account The address to remove from the whitelist
    function removeFromWhitelist(address account) external onlyOwner {
        require(whitelist[account], "Not in whitelist");
        whitelist[account] = false;
        delete whitelistURIs[account]; // Clear the URI
        
        // Remove from array
        uint256 index = whitelistIndex[account];
        require(index > 0, "Address not in whitelist array");
        index--; // Convert to 0-indexed
        
        // Move the last element to the deleted spot
        uint256 lastIndex = whitelistedAddresses.length - 1;
        if (index != lastIndex) {
            address lastAddress = whitelistedAddresses[lastIndex];
            whitelistedAddresses[index] = lastAddress;
            whitelistIndex[lastAddress] = index + 1; // Update index (1-indexed)
        }
        
        // Remove the last element
        whitelistedAddresses.pop();
        delete whitelistIndex[account];
        
        emit WhitelistRemoved(account);
    }

    /// @notice Check if an address is whitelisted
    /// @param account The address to check
    /// @return bool True if the address is whitelisted
    function isWhitelisted(address account) external view returns (bool) {
        return whitelist[account];
    }

    /// @notice Get the pre-assigned URI for a whitelisted address
    /// @param account The address to check
    /// @return string The URI assigned to this address
    function getWhitelistURI(address account) external view returns (string memory) {
        return whitelistURIs[account];
    }

    /// @notice Mint an NFT using pre-assigned URI (signature verification disabled for now)
    /// @param rwaAddress The address of the RWA contract to mint from
    /// @param signature ECDSA signature (currently unused, will be implemented later)
    function mintWithSignature(
        address rwaAddress,
        bytes memory signature
    ) external returns (uint256) {
        // Check if user is whitelisted
        require(whitelist[msg.sender], "Not whitelisted");
        
        // Check if user has a pre-assigned URI
        string memory uri = whitelistURIs[msg.sender];
        require(bytes(uri).length > 0, "No URI assigned for this address");
        
        // TODO: Add signature verification later
        // For now, just check if user has already minted
        require(!hasMinted[rwaAddress][msg.sender], "Already minted from this RWA");

        // Mark as minted
        hasMinted[rwaAddress][msg.sender] = true;
        
        // Update counters
        mintCountPerRWA[rwaAddress]++;
        totalMints++;

        // Call safeMint on the RWA contract (factory must be owner or have minting rights)
        RWA rwa = RWA(rwaAddress);
        uint256 tokenId = rwa.safeMint(msg.sender, uri);
        
        emit MintedWithSignature(rwaAddress, msg.sender, tokenId);
        return tokenId;
    }

    // ============ Statistics Functions ============

    /// @notice Get total number of deployed RWA contracts
    /// @return The total count of deployed RWAs
    function getTotalDeployedRWAs() external view returns (uint256) {
        return deployedRWAs.length;
    }

    /// @notice Get total number of whitelisted addresses
    /// @return The count of whitelisted addresses
    function getWhitelistCount() external view returns (uint256) {
        return whitelistedAddresses.length;
    }

    /// @notice Get total mints for a specific RWA contract
    /// @param rwaAddress The RWA contract address
    /// @return Total number of mints from this factory for that RWA
    function getTotalMintsForRWA(address rwaAddress) external view returns (uint256) {
        return mintCountPerRWA[rwaAddress];
    }

    // ============ Batch Query Functions ============

    /// @notice Check whitelist status for multiple addresses at once
    /// @param accounts Array of addresses to check
    /// @return Array of boolean values indicating whitelist status
    function isWhitelistedBatch(address[] calldata accounts) 
        external 
        view 
        returns (bool[] memory) 
    {
        bool[] memory results = new bool[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            results[i] = whitelist[accounts[i]];
        }
        return results;
    }

    /// @notice Get URIs for multiple whitelisted addresses
    /// @param accounts Array of addresses to query
    /// @return Array of URI strings
    function getWhitelistURIsBatch(address[] calldata accounts) 
        external 
        view 
        returns (string[] memory) 
    {
        string[] memory uris = new string[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            uris[i] = whitelistURIs[accounts[i]];
        }
        return uris;
    }

    /// @notice Check mint status for a user across multiple RWA contracts
    /// @param user The user address
    /// @param rwaAddresses Array of RWA contract addresses
    /// @return Array of boolean values indicating mint status
    function hasMintedBatch(address user, address[] calldata rwaAddresses) 
        external 
        view 
        returns (bool[] memory) 
    {
        bool[] memory results = new bool[](rwaAddresses.length);
        for (uint256 i = 0; i < rwaAddresses.length; i++) {
            results[i] = hasMinted[rwaAddresses[i]][user];
        }
        return results;
    }

    // ============ User Profile Functions ============

    /// @notice Get complete user information
    /// @param user The user address
    /// @return whitelisted Whether user is whitelisted
    /// @return uri The pre-assigned URI
    /// @return mintedRWAs Array of RWA addresses where user has minted
    function getUserInfo(address user) 
        external 
        view 
        returns (
            bool whitelisted,
            string memory uri,
            address[] memory mintedRWAs
        ) 
    {
        whitelisted = whitelist[user];
        uri = whitelistURIs[user];
        
        // Count how many RWAs this user has minted from
        uint256 mintCount = 0;
        for (uint256 i = 0; i < deployedRWAs.length; i++) {
            if (hasMinted[deployedRWAs[i]][user]) {
                mintCount++;
            }
        }
        
        // Build array of RWAs where user has minted
        mintedRWAs = new address[](mintCount);
        uint256 index = 0;
        for (uint256 i = 0; i < deployedRWAs.length; i++) {
            if (hasMinted[deployedRWAs[i]][user]) {
                mintedRWAs[index] = deployedRWAs[i];
                index++;
            }
        }
    }

    /// @notice Get all RWA contracts where user can still mint
    /// @param user The user address
    /// @return Available RWA addresses for minting
    function getAvailableRWAsForUser(address user) 
        external 
        view 
        returns (address[] memory) 
    {
        require(whitelist[user], "User not whitelisted");
        
        // Count available RWAs
        uint256 availableCount = 0;
        for (uint256 i = 0; i < deployedRWAs.length; i++) {
            if (!hasMinted[deployedRWAs[i]][user]) {
                availableCount++;
            }
        }
        
        // Build array of available RWAs
        address[] memory availableRWAs = new address[](availableCount);
        uint256 index = 0;
        for (uint256 i = 0; i < deployedRWAs.length; i++) {
            if (!hasMinted[deployedRWAs[i]][user]) {
                availableRWAs[index] = deployedRWAs[i];
                index++;
            }
        }
        
        return availableRWAs;
    }

    // ============ Whitelist Query Functions ============

    /// @notice Get all whitelisted addresses
    /// @return Array of all whitelisted addresses
    function getAllWhitelistedAddresses() 
        external 
        view 
        returns (address[] memory) 
    {
        return whitelistedAddresses;
    }

    /// @notice Get whitelisted addresses with pagination
    /// @param offset Starting index
    /// @param limit Number of items to return
    /// @return addresses Array of whitelisted addresses
    /// @return uris Array of corresponding URIs
    function getWhitelistedAddressesPaginated(uint256 offset, uint256 limit) 
        external 
        view 
        returns (address[] memory addresses, string[] memory uris) 
    {
        require(offset < whitelistedAddresses.length, "Offset out of bounds");
        
        uint256 end = offset + limit;
        if (end > whitelistedAddresses.length) {
            end = whitelistedAddresses.length;
        }
        
        uint256 resultLength = end - offset;
        addresses = new address[](resultLength);
        uris = new string[](resultLength);
        
        for (uint256 i = 0; i < resultLength; i++) {
            addresses[i] = whitelistedAddresses[offset + i];
            uris[i] = whitelistURIs[addresses[i]];
        }
    }

    // ============ Pagination Functions ============

    /// @notice Get deployed RWAs with pagination
    /// @param offset Starting index
    /// @param limit Number of items to return
    /// @return Slice of deployed RWA addresses
    function getDeployedRWAsPaginated(uint256 offset, uint256 limit) 
        external 
        view 
        returns (address[] memory) 
    {
        require(offset < deployedRWAs.length, "Offset out of bounds");
        
        uint256 end = offset + limit;
        if (end > deployedRWAs.length) {
            end = deployedRWAs.length;
        }
        
        uint256 resultLength = end - offset;
        address[] memory result = new address[](resultLength);
        
        for (uint256 i = 0; i < resultLength; i++) {
            result[i] = deployedRWAs[offset + i];
        }
        
        return result;
    }
}
