// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RWA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RWAFactory is Ownable {
    address[] public deployedRWAs;
    
    event RWADeployed(address indexed rwaAddress);

    constructor() Ownable(msg.sender) {}

    function createRWA() external onlyOwner returns (address) {
        RWA rwa = new RWA();
        deployedRWAs.push(address(rwa));
        emit RWADeployed(address(rwa));
        return address(rwa);
    }

    function getDeployedRWAs() external view returns (address[] memory) {
        return deployedRWAs;
    }

    function mintNFT(address rwaAddress, address to, string memory uri) external onlyOwner returns (uint256) {
        RWA rwa = RWA(rwaAddress);
        return rwa.safeMint(to, uri);
    }
}
