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
pragma experimental ABIEncoderV2;

import "dss-interfaces/dss/VatAbstract.sol";
import "dss-interfaces/dapp/DSPauseAbstract.sol";
import "dss-interfaces/dss/JugAbstract.sol";
import "dss-interfaces/dss/SpotAbstract.sol";
import "dss-interfaces/dss/GemJoinAbstract.sol";
import "dss-interfaces/dapp/DSTokenAbstract.sol";
import "dss-interfaces/dss/ChainlogAbstract.sol";
import "dss-interfaces/dss/IlkRegistryAbstract.sol";

import "./test/addresses_goerli.sol";

interface RwaLiquidationLike {
    function wards(address) external returns (uint256);

    function ilks(bytes32)
        external
        returns (
            string memory,
            address,
            uint48,
            uint48
        );

    function rely(address) external;

    function deny(address) external;

    function init(
        bytes32,
        uint256,
        string calldata,
        uint48
    ) external;

    function tell(bytes32) external;

    function cure(bytes32) external;

    function cull(bytes32) external;

    function good(bytes32) external view;
}

interface RwaOutputConduitLike {
    function wards(address) external returns (uint256);

    function can(address) external returns (uint256);

    function rely(address) external;

    function deny(address) external;

    function hope(address) external;

    function mate(address) external;

    function nope(address) external;

    function bud(address) external returns (uint256);

    function pick(address) external;

    function push() external;
}

interface RwaInputConduitLike {
    function rely(address usr) external;

    function deny(address usr) external;

    function mate(address usr) external;

    function hate(address usr) external;

    function push() external;
}

interface RwaUrnLike {
    function hope(address) external;
}

interface TokenDetailsLike {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract DssSpellCollateralOnboardingAction {

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
    uint256 constant ZERO_PCT_RATE = 1000000000000000000000000000;
    uint256 constant THREE_PCT_RATE = 1000000000937303470807876289; // TODO RWA team should provide this one

    // --- Math ---
    uint256 public constant THOUSAND = 10**3;
    uint256 public constant MILLION = 10**6;
    uint256 public constant WAD = 10**18;
    uint256 public constant RAY = 10**27;
    uint256 public constant RAD = 10**45;

    // GOERLI ADDRESSES

    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://github.com/clio-finance/ces-goerli/blob/master/contracts.json
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0x7EafEEa64bF6F79A79853F4A660e0960c821BA50);
    IlkRegistryAbstract constant REGISTRY = IlkRegistryAbstract(0x8E8049Eb87673aC30D8d17CdDF4f0a08b5e7Cc0d);

    address constant MIP21_LIQUIDATION_ORACLE = 0x493A7F7E6f44D3bd476bc1bfBBe191164269C0Cc;
    address constant RWA008 = 0xE3B8e9B2AdB2CE4B289C13F572b0426e6D8016B5;
    address constant MCD_JOIN_RWA008_A = 0xb7CBE4a7EE12c618Ef4b43FC620aB4e273f883E1;
    address constant RWA008_A_URN = 0xe42f68d8A8e955Be29AF833fdCCa92838271b007;
    address constant RWA008_A_INPUT_CONDUIT = 0x32c0254964697977a3aBC6Bad1D1E8C56Cc8fAb1;
    address constant RWA008_A_OUTPUT_CONDUIT = 0xcD6534b0f356d1b7b849974238Dd3733C9A1f2e5;
    address constant RWA008_A_OPERATOR = 0x3E774D9dfA578cc82C5b94a329230cD5736e9106;
    address constant RWA008_A_MATE = 0x969880695d8aDFB8e9C38982e07905CC42eD3fAd;
    address constant RWA008_A_TESTING_MATE = 0xc0b362cbb0117Ec6A4b589f744d4dECb2768A2eB;

    uint256 constant RWA008_A_INITIAL_DC = 80000000 * RAD; // TODO RWA team should provide
    uint256 constant RWA008_A_INITIAL_PRICE = 52 * MILLION * WAD; // TODO RWA team should provide
    uint48 constant RWA008_A_TAU = 1 weeks; // TODO RWA team should provide

    uint256 constant REG_CLASS_RWA = 3;

    /**
     * @notice MIP13c3-SP4 Declaration of Intent & Commercial Points -
     *   Off-Chain Asset Backed Lender to onboard Real World Assets
     *   as Collateral for a DAI loan
     *
     * https://ipfs.io/ipfs/QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk
     */
    string constant DOC = "QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk"; // TODO Reference to a documents which describe deal (should be uploaded to IPFS)

    // --- DEPLOYED COLLATERAL ADDRESSES ---

    function onboardNewCollaterals() internal {
        // --------------------------- RWA Collateral onboarding ---------------------------
        address MCD_VAT = ChainlogAbstract(CHANGELOG).getAddress("MCD_VAT");
        address MCD_JUG = ChainlogAbstract(CHANGELOG).getAddress("MCD_JUG");
        address MCD_SPOT = ChainlogAbstract(CHANGELOG).getAddress("MCD_SPOT");

        // RWA008-A collateral deploy

        // Set ilk bytes32 variable
        bytes32 ilk = "RWA008-A";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA008_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA008_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA008_A).gem() == RWA008, "join-gem-not-match");
        require(
            GemJoinAbstract(MCD_JOIN_RWA008_A).dec() == DSTokenAbstract(RWA008).decimals(),
            "join-dec-not-match"
        );

        /*
         * init the RwaLiquidationOracle2
         */
        // TODO: this should be verified with RWA Team (5 min for testing is good)
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(ilk, RWA008_A_INITIAL_PRICE, DOC, RWA008_A_TAU);
        (, address pip, , ) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);
        CHANGELOG.setAddress("PIP_RWA008", pip);

        // Set price feed for RWA008
        SpotAbstract(MCD_SPOT).file(ilk, "pip", pip);

        // Init RWA008 in Vat
        VatAbstract(MCD_VAT).init(ilk);
        // Init RWA008 in Jug
        JugAbstract(MCD_JUG).init(ilk);

        // Allow RWA008 Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_RWA008_A);

        // Allow RwaLiquidationOracle2 to modify Vat registry
        VatAbstract(MCD_VAT).rely(MIP21_LIQUIDATION_ORACLE);

        // 1000 debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", RWA008_A_INITIAL_DC);
        VatAbstract(MCD_VAT).file("Line", VatAbstract(MCD_VAT).Line() + RWA008_A_INITIAL_DC);

        // No dust
        // VatAbstract(MCD_VAT).file(ilk, "dust", 0)

        // 3% stability fee // TODO get from RWA
        JugAbstract(MCD_JUG).file(ilk, "duty", THREE_PCT_RATE);

        // collateralization ratio 100%
        SpotAbstract(MCD_SPOT).file(ilk, "mat", RAY); // TODO Should get from RWA team

        // poke the spotter to pull in a price
        SpotAbstract(MCD_SPOT).poke(ilk);

        // give the urn permissions on the join adapter
        GemJoinAbstract(MCD_JOIN_RWA008_A).rely(RWA008_A_URN);

        // set up the urn
        RwaUrnLike(RWA008_A_URN).hope(RWA008_A_OPERATOR);

        // set up output conduit
        RwaOutputConduitLike(RWA008_A_OUTPUT_CONDUIT).hope(RWA008_A_OPERATOR);

        // whitelist DIIS Group in the conduits
        RwaOutputConduitLike(RWA008_A_OUTPUT_CONDUIT).mate(RWA008_A_MATE);
        RwaInputConduitLike(RWA008_A_INPUT_CONDUIT).mate(RWA008_A_MATE);

        RwaOutputConduitLike(RWA008_A_OUTPUT_CONDUIT).mate(RWA008_A_TESTING_MATE);
        RwaInputConduitLike(RWA008_A_INPUT_CONDUIT).mate(RWA008_A_TESTING_MATE);

        // ChainLog Updates
        // CHANGELOG.setAddress("MIP21_LIQUIDATION_ORACLE", MIP21_LIQUIDATION_ORACLE);
        // Add RWA008 contract to the changelog
        CHANGELOG.setAddress("RWA008", RWA008);
        CHANGELOG.setAddress("MCD_JOIN_RWA008_A", MCD_JOIN_RWA008_A);
        CHANGELOG.setAddress("RWA008_A_URN", RWA008_A_URN);
        CHANGELOG.setAddress("RWA008_A_INPUT_CONDUIT", RWA008_A_INPUT_CONDUIT);
        CHANGELOG.setAddress("RWA008_A_OUTPUT_CONDUIT", RWA008_A_OUTPUT_CONDUIT);

        REGISTRY.put(
            "RWA008-A",
            MCD_JOIN_RWA008_A,
            RWA008,
            GemJoinAbstract(MCD_JOIN_RWA008_A).dec(),
            REG_CLASS_RWA,
            pip,
            address(0),
            TokenDetailsLike(RWA008).name(),
            TokenDetailsLike(RWA008).symbol()
        );
    }
}
