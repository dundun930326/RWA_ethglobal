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
        assertEq(rwa.owner(), initialOwner, "Ownership should be transferred to initialOwner");
    }

    function test_createRWA_deploys_additional_instance() public {
        address newOwner = address(0x1234);
        address addr = factory.createRWA(newOwner);
        // last pushed should be the same as returned address
        address[] memory rwAs = factory.getDeployedRWAs();
        assertEq(rwAs[rwAs.length - 1], addr, "createRWA should store new address");

        RWA rwa = RWA(addr);
        assertEq(rwa.owner(), newOwner, "New RWA ownership should be transferred to newOwner");
    }

    function test_mintWithSignature_whitelistedUserCanMint() public {
        // get the deployed RWA
        address[] memory rwAs = factory.getDeployedRWAs();
        address rwaAddress = rwAs[0];

        // the RWA contract needs to be owned by the factory for factory to call safeMint
        // transfer RWA ownership from initialOwner to factory
        vm.prank(initialOwner);
        RWA(rwaAddress).transferOwnership(address(factory));

        // choose a user who will mint
        address user = address(0xD0C);

        // Signature verification is disabled, just pass empty bytes
        bytes memory emptySignature = "";

        // user calls mintWithSignature on the factory
        vm.prank(user);
        uint256 tokenId = factory.mintWithSignature(rwaAddress, "ipfs://example", emptySignature);

        // verify minted
        RWA rwa = RWA(rwaAddress);
        assertEq(rwa.ownerOf(tokenId), user);
        assertTrue(factory.hasMinted(rwaAddress, user));
        assertEq(rwa.tokenURI(tokenId), "ipfs://example");
    }
}
