// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2021-2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.12;
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
// pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExecLib.sol";
import "dss-interfaces/dapp/DSTokenAbstract.sol";
import "dss-interfaces/dss/ChainlogAbstract.sol";
import "dss-interfaces/dss/GemJoinAbstract.sol";
import "dss-interfaces/dss/IlkRegistryAbstract.sol";
import "dss-interfaces/dss/JugAbstract.sol";
import "dss-interfaces/dss/SpotAbstract.sol";
import "dss-interfaces/dss/VatAbstract.sol";
import "dss-interfaces/ERC/GemAbstract.sol";

import "./test/addresses_goerli.sol";

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

interface RwaUrnLike {
    function hope(address) external;
    function lock(uint256) external;
}

interface RwaOutputConduitLike {
    function hope(address) external;
    function mate(address) external;
}

interface RwaInputConduitLike {
    function mate(address usr) external;
}

contract DssSpellCollateralAction {

    // --- Rates ---
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmTRiQ3GqjCiRhh1ojzKzgScmSsiwQPLyjhgYSxZASQekj

    // --- Rates  ---
    uint256 constant ZERO_PCT_RATE  = 1000000000000000000000000000;
    uint256 constant THREE_PCT_RATE = 1000000000937303470807876289; // TODO RWA team should provide this one

    // --- Math ---
    uint256 public constant THOUSAND = 10**3;
    uint256 public constant MILLION  = 10**6;
    uint256 public constant WAD      = 10**18;
    uint256 public constant RAY      = 10**27;
    uint256 public constant RAD      = 10**45;

    // GOERLI ADDRESSES

    address constant RWA999                  = 0x0000000000000000000000000000000000000000; // TODO CES team should provide
    address constant MCD_JOIN_RWA999_A       = 0x0000000000000000000000000000000000000000; // TODO CES team should provide
    address constant RWA999_A_URN            = 0x0000000000000000000000000000000000000000; // TODO CES team should provide
    address constant RWA999_A_INPUT_CONDUIT  = 0x0000000000000000000000000000000000000000; // TODO CES team should provide
    address constant RWA999_A_OUTPUT_CONDUIT = 0x0000000000000000000000000000000000000000; // TODO CES team should provide
    address constant RWA999_A_OPERATOR       = 0x0000000000000000000000000000000000000000; // TODO CES team should provide
    address constant RWA999_A_MATE           = 0x0000000000000000000000000000000000000000; // TODO CES team should provide

    uint256 constant RWA999_A_INITIAL_DC     = 80000000 * RAD;     // TODO RWA team should provide
    uint256 constant RWA999_A_INITIAL_PRICE  = 52 * MILLION * WAD; // TODO RWA team should provide
    uint48  constant RWA999_A_TAU            = 1 weeks;            // TODO RWA team should provide

    /**
     * @notice MIP13c3-SP4 Declaration of Intent & Commercial Points -
     *   Off-Chain Asset Backed Lender to onboard Real World Assets
     *   as Collateral for a DAI loan
     *
     * https://ipfs.io/ipfs/QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk
     */
    string constant DOC                      = ""; // TODO Reference to a documents which describe deal (should be uploaded to IPFS)

    uint256 constant REG_CLASS_RWA           = 3;

    // --- DEPLOYED COLLATERAL ADDRESSES ---

    function onboardNewCollaterals() internal {
        ChainlogAbstract CHANGELOG       = ChainlogAbstract(DssExecLib.LOG);
        IlkRegistryAbstract REGISTRY     = IlkRegistryAbstract(DssExecLib.reg());
        address MIP21_LIQUIDATION_ORACLE = CHANGELOG.getAddress("MIP21_LIQUIDATION_ORACLE");
        address MCD_VAT                  = CHANGELOG.getAddress("MCD_VAT");
        address MCD_JUG                  = CHANGELOG.getAddress("MCD_JUG");
        address MCD_SPOT                 = CHANGELOG.getAddress("MCD_SPOT");

        // RWA999-A collateral deploy

        // Set ilk bytes32 variable
        bytes32 ilk = "RWA999-A";
        uint256 decimals = DSTokenAbstract(RWA999).decimals();

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA999_A).vat() == MCD_VAT,  "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA999_A).ilk() == ilk,      "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA999_A).gem() == RWA999,   "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA999_A).dec() == decimals, "join-dec-not-match");

        require(RwaUrnLike(RWA009_A_URN).vat() == MCD_VAT,               "urn-vat-not-match");
        require(RwaUrnLike(RWA009_A_URN).jug() == MCD_JUG,               "urn-jug-not-match");
        require(RwaUrnLike(RWA009_A_URN).daiJoin() == MCD_JOIN_DAI,      "urn-daijoin-not-match");
        require(RwaUrnLike(RWA009_A_URN).gemJoin() == MCD_JOIN_RWA009_A, "urn-gemjoin-not-match");

        /*
         * init the RwaLiquidationOracle2
         */
        // TODO: this should be verified with RWA Team (5 min for testing is good)
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(ilk, RWA999_A_INITIAL_PRICE, DOC, RWA999_A_TAU);
        (, address pip, , ) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Set price feed for RWA999
        SpotAbstract(MCD_SPOT).file(ilk, "pip", pip);

        // Init RWA999 in Vat
        VatAbstract(MCD_VAT).init(ilk);
        // Init RWA999 in Jug
        JugAbstract(MCD_JUG).init(ilk);

        // Allow RWA999 Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_RWA999_A);

        // Allow RwaLiquidationOracle2 to modify Vat registry
        VatAbstract(MCD_VAT).rely(MIP21_LIQUIDATION_ORACLE);

        // 1000 debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", RWA999_A_INITIAL_DC);
        VatAbstract(MCD_VAT).file("Line", VatAbstract(MCD_VAT).Line() + RWA999_A_INITIAL_DC);

        // No dust
        // VatAbstract(MCD_VAT).file(ilk, "dust", 0)

        // 3% stability fee // TODO get from RWA
        JugAbstract(MCD_JUG).file(ilk, "duty", THREE_PCT_RATE);

        // collateralization ratio 100%
        SpotAbstract(MCD_SPOT).file(ilk, "mat", RAY); // TODO Should get from RWA team

        // poke the spotter to pull in a price
        SpotAbstract(MCD_SPOT).poke(ilk);

        // give the urn permissions on the join adapter
        GemJoinAbstract(MCD_JOIN_RWA999_A).rely(RWA999_A_URN);

        // set up the urn
        RwaUrnLike(RWA999_A_URN).hope(RWA999_A_OPERATOR);

        // set up output conduit
        RwaOutputConduitLike(RWA999_A_OUTPUT_CONDUIT).hope(RWA999_A_OPERATOR);

        // whitelist DIIS Group in the conduits
        RwaOutputConduitLike(RWA999_A_OUTPUT_CONDUIT).mate(RWA999_A_MATE);
        RwaInputConduitLike(RWA999_A_INPUT_CONDUIT)  .mate(RWA999_A_MATE);

        // sent RWA999 to RWA999_A_OPERATOR
        DSTokenAbstract(RWA999).transfer(RWA999_A_OPERATOR, 1 * WAD);

        // ChainLog Updates
        // CHANGELOG.setAddress("MIP21_LIQUIDATION_ORACLE", MIP21_LIQUIDATION_ORACLE);
        // Add RWA999 contracts to the changelog
        CHANGELOG.setAddress("RWA999",                  RWA999);
        CHANGELOG.setAddress("PIP_RWA999",              pip);
        CHANGELOG.setAddress("MCD_JOIN_RWA999_A",       MCD_JOIN_RWA999_A);
        CHANGELOG.setAddress("RWA999_A_URN",            RWA999_A_URN);
        CHANGELOG.setAddress("RWA999_A_INPUT_CONDUIT",  RWA999_A_INPUT_CONDUIT);
        CHANGELOG.setAddress("RWA999_A_OUTPUT_CONDUIT", RWA999_A_OUTPUT_CONDUIT);

        REGISTRY.put(
            "RWA999-A",
            MCD_JOIN_RWA999_A,
            RWA999,
            GemJoinAbstract(MCD_JOIN_RWA999_A).dec(),
            REG_CLASS_RWA,
            pip,
            address(0),
            // Either provide a name like:
            "RWA999-A: Some RWA Deal",
            // ... or use the token name:
            // GemAbstract(RWA999).name(),
            GemAbstract(RWA999).symbol()
        );
    }

    function offboardCollaterals() internal {}
}
