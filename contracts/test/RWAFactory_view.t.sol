// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RWAFactory.sol";
import "../src/RWA.sol";

contract RWAFactoryViewTest is Test {
    RWAFactory public factory;
    RWA public rwa1;
    RWA public rwa2;
    
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public user3 = address(4);
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy factory
        factory = new RWAFactory(owner);
        
        // Get the first RWA deployed in constructor
        rwa1 = RWA(factory.deployedRWAs(0));
        
        // Deploy a second RWA through the factory
        address rwa2Address = factory.createRWA();
        rwa2 = RWA(rwa2Address);
        
        // Add users to whitelist with URIs
        factory.addToWhitelist(user1, "ipfs://user1-metadata");
        factory.addToWhitelist(user2, "ipfs://user2-metadata");
        factory.addToWhitelist(user3, "ipfs://user3-metadata");
        
        vm.stopPrank();
    }
    
    // ============ Statistics Functions Tests ============
    
    function testGetTotalDeployedRWAs() public {
        uint256 total = factory.getTotalDeployedRWAs();
        assertEq(total, 2, "Should have 2 deployed RWAs");
    }
    
    function testGetWhitelistCount() public {
        uint256 count = factory.getWhitelistCount();
        assertEq(count, 3, "Should have 3 whitelisted addresses");
    }
    
    function testGetTotalMintsForRWA() public {
        // Initially no mints
        assertEq(factory.getTotalMintsForRWA(address(rwa1)), 0, "Should have 0 mints initially");
        
        // Mint for user1
        vm.prank(user1);
        factory.mintWithSignature(address(rwa1), "");
        
        assertEq(factory.getTotalMintsForRWA(address(rwa1)), 1, "Should have 1 mint after user1 mints");
        
        // Mint for user2
        vm.prank(user2);
        factory.mintWithSignature(address(rwa1), "");
        
        assertEq(factory.getTotalMintsForRWA(address(rwa1)), 2, "Should have 2 mints after user2 mints");
    }
    
    function testGetTotalMints() public {
        assertEq(factory.totalMints(), 0, "Should have 0 total mints initially");
        
        // User1 mints from rwa1
        vm.prank(user1);
        factory.mintWithSignature(address(rwa1), "");
        assertEq(factory.totalMints(), 1, "Should have 1 total mint");
        
        // User2 mints from rwa2
        vm.prank(user2);
        factory.mintWithSignature(address(rwa2), "");
        assertEq(factory.totalMints(), 2, "Should have 2 total mints");
    }
    
    // ============ Batch Query Functions Tests ============
    
    function testIsWhitelistedBatch() public {
        address[] memory accounts = new address[](4);
        accounts[0] = user1;
        accounts[1] = user2;
        accounts[2] = user3;
        accounts[3] = address(999); // Not whitelisted
        
        bool[] memory results = factory.isWhitelistedBatch(accounts);
        
        assertTrue(results[0], "User1 should be whitelisted");
        assertTrue(results[1], "User2 should be whitelisted");
        assertTrue(results[2], "User3 should be whitelisted");
        assertFalse(results[3], "Address 999 should not be whitelisted");
    }
    
    function testGetWhitelistURIsBatch() public {
        address[] memory accounts = new address[](3);
        accounts[0] = user1;
        accounts[1] = user2;
        accounts[2] = user3;
        
        string[] memory uris = factory.getWhitelistURIsBatch(accounts);
        
        assertEq(uris[0], "ipfs://user1-metadata", "User1 URI should match");
        assertEq(uris[1], "ipfs://user2-metadata", "User2 URI should match");
        assertEq(uris[2], "ipfs://user3-metadata", "User3 URI should match");
    }
    
    function testHasMintedBatch() public {
        // User1 mints from rwa1
        vm.prank(user1);
        factory.mintWithSignature(address(rwa1), "");
        
        address[] memory rwaAddresses = new address[](2);
        rwaAddresses[0] = address(rwa1);
        rwaAddresses[1] = address(rwa2);
        
        bool[] memory results = factory.hasMintedBatch(user1, rwaAddresses);
        
        assertTrue(results[0], "User1 should have minted from rwa1");
        assertFalse(results[1], "User1 should not have minted from rwa2");
    }
    
    // ============ User Profile Functions Tests ============
    
    function testGetUserInfo() public {
        (bool whitelisted, string memory uri, address[] memory mintedRWAs) = factory.getUserInfo(user1);
        
        assertTrue(whitelisted, "User1 should be whitelisted");
        assertEq(uri, "ipfs://user1-metadata", "User1 URI should match");
        assertEq(mintedRWAs.length, 0, "User1 should have 0 minted RWAs initially");
        
        // User1 mints from both RWAs
        vm.startPrank(user1);
        factory.mintWithSignature(address(rwa1), "");
        factory.mintWithSignature(address(rwa2), "");
        vm.stopPrank();
        
        (whitelisted, uri, mintedRWAs) = factory.getUserInfo(user1);
        assertEq(mintedRWAs.length, 2, "User1 should have 2 minted RWAs");
        assertEq(mintedRWAs[0], address(rwa1), "First minted RWA should be rwa1");
        assertEq(mintedRWAs[1], address(rwa2), "Second minted RWA should be rwa2");
    }
    
    function testGetUserInfoNotWhitelisted() public {
        address notWhitelisted = address(999);
        (bool whitelisted, string memory uri, address[] memory mintedRWAs) = factory.getUserInfo(notWhitelisted);
        
        assertFalse(whitelisted, "Address should not be whitelisted");
        assertEq(bytes(uri).length, 0, "URI should be empty");
        assertEq(mintedRWAs.length, 0, "Should have no minted RWAs");
    }
    
    function testGetAvailableRWAsForUser() public {
        address[] memory available = factory.getAvailableRWAsForUser(user1);
        assertEq(available.length, 2, "User1 should have 2 available RWAs");
        
        // User1 mints from rwa1
        vm.prank(user1);
        factory.mintWithSignature(address(rwa1), "");
        
        available = factory.getAvailableRWAsForUser(user1);
        assertEq(available.length, 1, "User1 should have 1 available RWA after minting");
        assertEq(available[0], address(rwa2), "Available RWA should be rwa2");
        
        // User1 mints from rwa2
        vm.prank(user1);
        factory.mintWithSignature(address(rwa2), "");
        
        available = factory.getAvailableRWAsForUser(user1);
        assertEq(available.length, 0, "User1 should have 0 available RWAs after minting all");
    }
    
    function testGetAvailableRWAsForUserNotWhitelisted() public {
        vm.expectRevert("User not whitelisted");
        factory.getAvailableRWAsForUser(address(999));
    }
    
    // ============ Whitelist Query Functions Tests ============
    
    function testGetAllWhitelistedAddresses() public {
        address[] memory whitelisted = factory.getAllWhitelistedAddresses();
        assertEq(whitelisted.length, 3, "Should have 3 whitelisted addresses");
        assertEq(whitelisted[0], user1, "First should be user1");
        assertEq(whitelisted[1], user2, "Second should be user2");
        assertEq(whitelisted[2], user3, "Third should be user3");
    }
    
    function testGetWhitelistedAddressesPaginated() public {
        (address[] memory addresses, string[] memory uris) = factory.getWhitelistedAddressesPaginated(0, 2);
        
        assertEq(addresses.length, 2, "Should return 2 addresses");
        assertEq(uris.length, 2, "Should return 2 URIs");
        assertEq(addresses[0], user1, "First address should be user1");
        assertEq(addresses[1], user2, "Second address should be user2");
        assertEq(uris[0], "ipfs://user1-metadata", "First URI should match");
        assertEq(uris[1], "ipfs://user2-metadata", "Second URI should match");
        
        // Test second page
        (addresses, uris) = factory.getWhitelistedAddressesPaginated(2, 2);
        assertEq(addresses.length, 1, "Should return 1 address (last page)");
        assertEq(addresses[0], user3, "Address should be user3");
    }
    
    function testGetWhitelistedAddressesPaginatedOutOfBounds() public {
        vm.expectRevert("Offset out of bounds");
        factory.getWhitelistedAddressesPaginated(10, 2);
    }
    
    // ============ Pagination Functions Tests ============
    
    function testGetDeployedRWAsPaginated() public {
        address[] memory rwas = factory.getDeployedRWAsPaginated(0, 1);
        assertEq(rwas.length, 1, "Should return 1 RWA");
        assertEq(rwas[0], address(rwa1), "First RWA should be rwa1");
        
        rwas = factory.getDeployedRWAsPaginated(1, 1);
        assertEq(rwas.length, 1, "Should return 1 RWA");
        assertEq(rwas[0], address(rwa2), "Second RWA should be rwa2");
        
        // Get all at once
        rwas = factory.getDeployedRWAsPaginated(0, 10);
        assertEq(rwas.length, 2, "Should return all 2 RWAs");
    }
    
    function testGetDeployedRWAsPaginatedOutOfBounds() public {
        vm.expectRevert("Offset out of bounds");
        factory.getDeployedRWAsPaginated(10, 2);
    }
    
    // ============ Edge Cases Tests ============
    
    function testWhitelistManipulation() public {
        vm.startPrank(owner);
        
        // Add user4
        address user4 = address(5);
        factory.addToWhitelist(user4, "ipfs://user4-metadata");
        assertEq(factory.getWhitelistCount(), 4, "Should have 4 whitelisted addresses");
        
        // Remove user2
        factory.removeFromWhitelist(user2);
        assertEq(factory.getWhitelistCount(), 3, "Should have 3 whitelisted addresses after removal");
        
        // Check user2 is not in whitelist
        assertFalse(factory.whitelist(user2), "User2 should not be in whitelist");
        
        // Check other users are still in whitelist
        assertTrue(factory.whitelist(user1), "User1 should still be in whitelist");
        assertTrue(factory.whitelist(user3), "User3 should still be in whitelist");
        assertTrue(factory.whitelist(user4), "User4 should be in whitelist");
        
        vm.stopPrank();
    }
    
    function testBatchAddAndQuery() public {
        vm.startPrank(owner);
        
        address[] memory newUsers = new address[](3);
        string[] memory newURIs = new string[](3);
        
        newUsers[0] = address(10);
        newUsers[1] = address(11);
        newUsers[2] = address(12);
        
        newURIs[0] = "ipfs://user10-metadata";
        newURIs[1] = "ipfs://user11-metadata";
        newURIs[2] = "ipfs://user12-metadata";
        
        factory.addToWhitelistBatch(newUsers, newURIs);
        
        assertEq(factory.getWhitelistCount(), 6, "Should have 6 whitelisted addresses");
        
        bool[] memory results = factory.isWhitelistedBatch(newUsers);
        assertTrue(results[0], "User10 should be whitelisted");
        assertTrue(results[1], "User11 should be whitelisted");
        assertTrue(results[2], "User12 should be whitelisted");
        
        vm.stopPrank();
    }
    
    function testComplexUserJourney() public {
        // User1 checks available RWAs
        address[] memory available = factory.getAvailableRWAsForUser(user1);
        assertEq(available.length, 2, "User1 should have 2 available RWAs");
        
        // User1 mints from first RWA
        vm.prank(user1);
        factory.mintWithSignature(available[0], "");
        
        // Check stats
        assertEq(factory.totalMints(), 1, "Should have 1 total mint");
        assertEq(factory.getTotalMintsForRWA(available[0]), 1, "RWA should have 1 mint");
        
        // Get user info
        (bool whitelisted, string memory uri, address[] memory mintedRWAs) = factory.getUserInfo(user1);
        assertTrue(whitelisted, "User1 should be whitelisted");
        assertEq(mintedRWAs.length, 1, "User1 should have 1 minted RWA");
        
        // Check available RWAs again
        available = factory.getAvailableRWAsForUser(user1);
        assertEq(available.length, 1, "User1 should have 1 available RWA left");
    }
}
