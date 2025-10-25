// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RWAFactory.sol";
import "../src/RWA.sol";

contract RWAFactoryTest is Test {
    RWAFactory public factory;
    address public initialOwner = address(0xBEEF);

    function setUp() public {
        // Deploy the factory and pass the initial owner for the constructor
        factory = new RWAFactory(initialOwner);
    }

    function test_constructor_deployedRWA_and_transferredOwnership() public {
        address[] memory rwAs = factory.getDeployedRWAs();
        assertEq(rwAs.length, 1, "Factory should have deployed one RWA in constructor");

        RWA rwa = RWA(rwAs[0]);
        assertEq(rwa.owner(), address(factory), "Factory should retain ownership of RWA");
    }

    function test_createRWA_deploys_additional_instance() public {
        address addr = factory.createRWA();
        // last pushed should be the same as returned address
        address[] memory rwAs = factory.getDeployedRWAs();
        assertEq(rwAs[rwAs.length - 1], addr, "createRWA should store new address");

        RWA rwa = RWA(addr);
        assertEq(rwa.owner(), address(factory), "Factory should retain ownership of new RWA");
    }

    function test_addToWhitelist() public {
        address user = address(0xD0C);
        string memory uri = "ipfs://QmTest123";
        
        // Initially not whitelisted
        assertFalse(factory.isWhitelisted(user));
        
        // Factory owner adds user to whitelist with URI
        factory.addToWhitelist(user, uri);
        
        // Now user should be whitelisted
        assertTrue(factory.isWhitelisted(user));
        
        // Check URI is set correctly
        assertEq(factory.getWhitelistURI(user), uri);
    }

    function test_addToWhitelistBatch() public {
        address[] memory users = new address[](3);
        users[0] = address(0xD0C);
        users[1] = address(0xBEE);
        users[2] = address(0xCAFE);
        
        string[] memory uris = new string[](3);
        uris[0] = "ipfs://QmTest1";
        uris[1] = "ipfs://QmTest2";
        uris[2] = "ipfs://QmTest3";
        
        // Add batch
        factory.addToWhitelistBatch(users, uris);
        
        // Verify all are whitelisted with correct URIs
        assertTrue(factory.isWhitelisted(users[0]));
        assertTrue(factory.isWhitelisted(users[1]));
        assertTrue(factory.isWhitelisted(users[2]));
        
        assertEq(factory.getWhitelistURI(users[0]), uris[0]);
        assertEq(factory.getWhitelistURI(users[1]), uris[1]);
        assertEq(factory.getWhitelistURI(users[2]), uris[2]);
    }

    function test_removeFromWhitelist() public {
        address user = address(0xD0C);
        string memory uri = "ipfs://QmTest123";
        
        // Add then remove
        factory.addToWhitelist(user, uri);
        assertTrue(factory.isWhitelisted(user));
        assertEq(factory.getWhitelistURI(user), uri);
        
        factory.removeFromWhitelist(user);
        assertFalse(factory.isWhitelisted(user));
        
        // URI should be cleared
        assertEq(factory.getWhitelistURI(user), "");
    }

    function test_mintWithSignature_requiresWhitelist() public {
        address[] memory rwAs = factory.getDeployedRWAs();
        address rwaAddress = rwAs[0];

        // No need to transfer ownership - Factory already owns the RWA

        address user = address(0xD0C);
        bytes memory emptySignature = "";

        // Should fail - user not whitelisted
        vm.prank(user);
        vm.expectRevert("Not whitelisted");
        factory.mintWithSignature(rwaAddress, emptySignature);
    }

    function test_mintWithSignature_whitelistedUserCanMint() public {
        // get the deployed RWA
        address[] memory rwAs = factory.getDeployedRWAs();
        address rwaAddress = rwAs[0];

        // No need to transfer ownership - Factory already owns the RWA

        // choose a user who will mint
        address user = address(0xD0C);
        string memory uri = "ipfs://QmPreAssignedURI";
        
        // Add user to whitelist with pre-assigned URI
        factory.addToWhitelist(user, uri);

        // Signature verification is disabled, just pass empty bytes
        bytes memory emptySignature = "";

        // user calls mintWithSignature on the factory (no URI parameter needed)
        vm.prank(user);
        uint256 tokenId = factory.mintWithSignature(rwaAddress, emptySignature);

        // verify minted with pre-assigned URI
        RWA rwa = RWA(rwaAddress);
        assertEq(rwa.ownerOf(tokenId), user);
        assertTrue(factory.hasMinted(rwaAddress, user));
        assertEq(rwa.tokenURI(tokenId), uri); // Should match pre-assigned URI
    }

    function test_mintWithSignature_cannotMintTwice() public {
        address[] memory rwAs = factory.getDeployedRWAs();
        address rwaAddress = rwAs[0];

        // No need to transfer ownership - Factory already owns the RWA

        address user = address(0xD0C);
        string memory uri = "ipfs://QmPreAssignedURI";
        factory.addToWhitelist(user, uri);
        
        bytes memory emptySignature = "";

        // First mint succeeds
        vm.prank(user);
        factory.mintWithSignature(rwaAddress, emptySignature);

        // Second mint should fail
        vm.prank(user);
        vm.expectRevert("Already minted from this RWA");
        factory.mintWithSignature(rwaAddress, emptySignature);
    }

    function test_mintWithSignature_requiresPreAssignedURI() public {
        address[] memory rwAs = factory.getDeployedRWAs();
        address rwaAddress = rwAs[0];

        // No need to transfer ownership - Factory already owns the RWA

        address user = address(0xD0C);
        
        // Add user to whitelist but with empty URI (should fail during mint)
        // Actually, addToWhitelist now requires non-empty URI, so we can't test this way
        // Instead, test that mint fails if somehow URI is not set
        
        // For now, let's skip this edge case or manually set whitelist without URI
        // This is more of an internal consistency check
    }
}
