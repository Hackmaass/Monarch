// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MonarchCertificate.sol";

/// @title Deploy
/// @notice Foundry deployment script for the MonarchCertificate contract.
/// @dev Usage:
///   1. Set environment variables:
///        DEPLOYER_PRIVATE_KEY — private key of the deploying wallet
///        BASE_SEPOLIA_RPC     — RPC endpoint for Base Sepolia
///   2. Run:
///        forge script script/Deploy.s.sol:Deploy \
///          --rpc-url $BASE_SEPOLIA_RPC \
///          --broadcast \
///          --verify
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        MonarchCertificate certificate = new MonarchCertificate(deployer);

        vm.stopBroadcast();

        console.log("========================================");
        console.log("MonarchCertificate deployed at:", address(certificate));
        console.log("Owner:", certificate.owner());
        console.log("Chain ID:", block.chainid);
        console.log("========================================");
    }
}
