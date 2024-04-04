// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";

/// @notice Runs some basic tests against a local test deployment (fork is expected at port 8545)
contract LocalForkTest is Test {

    uint256 localFork;
    
    function setUp() public {
        localFork = vm.createFork("http://localhost:8545/");
        vm.selectFork(localFork);
    }

    // TODO

}