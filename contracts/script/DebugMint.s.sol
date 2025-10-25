// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RWAFactory.sol";
import "../src/RWA.sol";

/**
 * @title DebugMint
 * @dev Script to help diagnose mintWithSignature issues
 * 
 * Usage:
 * forge script script/DebugMint.s.sol:DebugMint --rpc-url <YOUR_RPC_URL>
 */
contract DebugMint is Script {
    function run() external view {
        // Replace these with your actual deployed addresses
        address factoryAddress = 0x0000000000000000000000000000000000000000; // Your factory address - REPLACE THIS
        address userAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // Your user address - REPLACE THIS
        
        RWAFactory factory = RWAFactory(factoryAddress);
        
        console.log("=== Debugging mintWithSignature ===");
        console.log("");
        
        // Check 1: Is user whitelisted?
        bool isWhitelisted = factory.whitelist(userAddress);
        console.log("1. Is user whitelisted?", isWhitelisted);
        if (!isWhitelisted) {
            console.log("   ERROR: User is NOT in whitelist!");
            console.log("   Solution: Call factory.addToWhitelist(userAddress, uri)");
            return;
        }
        
        // Check 2: Does user have a URI?
        string memory uri = factory.whitelistURIs(userAddress);
        console.log("2. User's assigned URI:", uri);
        if (bytes(uri).length == 0) {
            console.log("   ERROR: User has no URI assigned!");
            console.log("   Solution: Call factory.addToWhitelist(userAddress, uri)");
            return;
        }
        
        // Check 3: Get all deployed RWAs
        address[] memory deployedRWAs = factory.getDeployedRWAs();
        console.log("3. Total deployed RWAs:", deployedRWAs.length);
        
        if (deployedRWAs.length == 0) {
            console.log("   ERROR: No RWA contracts deployed!");
            console.log("   Solution: Call factory.createRWA()");
            return;
        }
        
        // Check each RWA
        for (uint256 i = 0; i < deployedRWAs.length; i++) {
            address rwaAddress = deployedRWAs[i];
            console.log("");
            console.log("   RWA #", i, ":", rwaAddress);
            
            // Check 4: Has user already minted?
            bool alreadyMinted = factory.hasMinted(rwaAddress, userAddress);
            console.log("   - Already minted?", alreadyMinted);
            
            // Check 5: Who is the owner of this RWA?
            RWA rwa = RWA(rwaAddress);
            address rwaOwner = rwa.owner();
            console.log("   - RWA owner:", rwaOwner);
            console.log("   - Factory address:", address(factory));
            console.log("   - Is factory the owner?", rwaOwner == address(factory));
            
            if (rwaOwner != address(factory)) {
                console.log("   ERROR: Factory is NOT the owner of this RWA!");
                console.log("   Solution: RWA ownership must be transferred to Factory");
                console.log("   or deploy new RWA via factory.createRWA()");
            }
        }
        
        console.log("");
        console.log("=== Summary ===");
        console.log("If all checks pass, mintWithSignature should work.");
        console.log("Make sure you're calling:");
        console.log("factory.mintWithSignature(rwaAddress, \"\")");
    }
}
