// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
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
import "dss-interfaces/dss/GemJoinAbstract.sol";
import "dss-interfaces/dss/IlkRegistryAbstract.sol";
import "dss-interfaces/ERC/GemAbstract.sol";
import "dss-interfaces/dss/mip21/RwaLiquidationOracleAbstract.sol";
import "dss-interfaces/dss/mip21/RwaUrnAbstract.sol";
import "dss-interfaces/dss/mip21/RwaJarAbstract.sol";
import "dss-interfaces/dss/mip21/RwaOutputConduitAbstract.sol";
import "dss-interfaces/dss/mip21/RwaInputConduitAbstract.sol";

contract DssSpellCollateralAction {
    // --- Rates ---
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //

    // --- Math ---
    uint256 internal constant WAD = 10**18;

    // -- RWAXXX MIP21 components --
    address internal constant RWAXXX                         = 0x0000000000000000000000000000000000000000; // TODO
    address internal constant MCD_JOIN_RWAXXX_A              = 0x0000000000000000000000000000000000000000; // TODO
    address internal constant RWAXXX_A_URN                   = 0x0000000000000000000000000000000000000000; // TODO
    address internal constant RWAXXX_A_JAR                   = 0x0000000000000000000000000000000000000000; // TODO
    address internal constant RWAXXX_A_OUTPUT_CONDUIT        = 0x0000000000000000000000000000000000000000; // TODO
    // Jar and URN Input Conduits
    address internal constant RWAXXX_A_INPUT_CONDUIT         = 0x0000000000000000000000000000000000000000; // TODO
    // RWAXXX_A_INPUT_CONDUIT_JAR is only required if fee payments are made in a token other than Dai.
    // address internal constant RWAXXX_A_INPUT_CONDUIT_JAR     = 0x0000000000000000000000000000000000000000; // TODO

    // MIP21_LIQUIDATION_ORACLE params

    // https://gateway.pinata.cloud/ipfs/TODO
    string  internal constant RWAXXX_DOC                     = "TODO";
    // There is no DssExecLib helper, so WAD precision is used.
    uint256 internal constant RWAXXX_A_INITIAL_PRICE         = 250_000_000 * WAD;
    uint48  internal constant RWAXXX_A_TAU                   = 0;

    // Ilk registry params
    uint256 internal constant REG_CLASS_RWA                  = 3;

    // Remaining params
    uint256 internal constant RWAXXX_A_LINE                  = 1_000_000;
    uint256 internal constant RWAXXX_A_MAT                   = 100_00; // 100% in basis-points

    // Operator address
    address internal constant RWAXXX_A_OPERATOR              = 0x0000000000000000000000000000000000000000; // TODO
    // Custody address
    address internal constant RWAXXX_A_CUSTODY               = 0x0000000000000000000000000000000000000000; // TODO

    // -- RWAXXX END --

    function onboardRwaXXX(
        IlkRegistryAbstract REGISTRY,
        address MIP21_LIQUIDATION_ORACLE,
        address MCD_VAT,
        address MCD_JUG,
        address MCD_SPOT,
        address MCD_JOIN_DAI
       /* , MCD_PSM_XXXX_A */
    ) internal {
        // RWAXXX-A collateral deploy
        bytes32 ilk      = "RWAXXX-A";
        uint256 decimals = GemAbstract(RWAXXX).decimals();

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWAXXX_A).vat()                             == MCD_VAT,                                    "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWAXXX_A).ilk()                             == ilk,                                        "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWAXXX_A).gem()                             == RWAXXX,                                     "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWAXXX_A).dec()                             == decimals,                                   "join-dec-not-match");

        require(RwaUrnAbstract(RWAXXX_A_URN).vat()                                       == MCD_VAT,                                    "urn-vat-not-match");
        require(RwaUrnAbstract(RWAXXX_A_URN).jug()                                       == MCD_JUG,                                    "urn-jug-not-match");
        require(RwaUrnAbstract(RWAXXX_A_URN).daiJoin()                                   == MCD_JOIN_DAI,                               "urn-daijoin-not-match");
        require(RwaUrnAbstract(RWAXXX_A_URN).gemJoin()                                   == MCD_JOIN_RWAXXX_A,                          "urn-gemjoin-not-match");
        require(RwaUrnAbstract(RWAXXX_A_URN).outputConduit()                             == RWAXXX_A_OUTPUT_CONDUIT,                    "urn-outputconduit-not-match");
        
        require(RwaJarAbstract(RWAXXX_A_JAR).chainlog()                                  == DssExecLib.LOG,                             "jar-chainlog-not-match");
        require(RwaJarAbstract(RWAXXX_A_JAR).dai()                                       == DssExecLib.dai(),                           "jar-dai-not-match");
        require(RwaJarAbstract(RWAXXX_A_JAR).daiJoin()                                   == MCD_JOIN_DAI,                               "jar-daijoin-not-match");

        require(RwaOutputConduitAbstract(RWAXXX_A_OUTPUT_CONDUIT).dai()                  == DssExecLib.dai(),                           "output-conduit-dai-not-match");
        // Uncomment if the requires uses a PSM to swap Dai into another token.
        // require(RwaOutputConduitAbstract(RWAXXX_A_OUTPUT_CONDUIT).gem()                  == DssExecLib.getChangelogAddress("USDC"),     "output-conduit-gem-not-match");
        // Uncomment if the requires uses a PSM to swap Dai into another token.
        // require(RwaOutputConduit3Abstract(RWAXXX_A_OUTPUT_CONDUIT).psm()                  == MCD_PSM_USDC_A,                             "output-conduit-psm-not-match");
        
        // Uncomment if the requires uses a PSM to swap Dai into another token.
        // require(RwaOutputConduit3Abstract(RWAXXX_A_INPUT_CONDUIT).psm()                == MCD_PSM_USDC_A,                             "input-conduit-urn-psm-not-match");
        require(RwaOutputConduitAbstract(RWAXXX_A_INPUT_CONDUIT).to()                 == RWAXXX_A_URN,                               "input-conduit-urn-to-not-match");
        require(RwaOutputConduitAbstract(RWAXXX_A_INPUT_CONDUIT).dai()                == DssExecLib.dai(),                           "input-conduit-urn-dai-not-match");
        // Uncomment if the requires uses a PSM to swap Dai into another token.
        // require(RwaOutputConduitAbstract(RWAXXX_A_INPUT_CONDUIT).gem()                == DssExecLib.getChangelogAddress("USDC"),     "input-conduit-urn-gem-not-match");

        // Uncomment if the requires uses a PSM to swap Dai into another token.
        // require(RwaInputConduit3Abstract(RWAXXX_A_INPUT_CONDUIT_JAR).psm()                == MCD_PSM_USDC_A,                             "input-conduit-jar-psm-not-match");
        // require(RwaInputConduit3Abstract(RWAXXX_A_INPUT_CONDUIT_JAR).to()                 == RWAXXX_A_JAR,                               "input-conduit-jar-to-not-match");
        // require(RwaInputConduit3Abstract(RWAXXX_A_INPUT_CONDUIT_JAR).dai()                == DssExecLib.dai(),                           "input-conduit-jar-dai-not-match");
        // require(RwaInputConduit3Abstract(RWAXXX_A_INPUT_CONDUIT_JAR).gem()                == DssExecLib.getChangelogAddress("USDC"),     "input-conduit-jar-gem-not-match");


        // Init the RwaLiquidationOracle
        RwaLiquidationOracleAbstract(MIP21_LIQUIDATION_ORACLE).init(ilk, RWAXXX_A_INITIAL_PRICE, RWAXXX_DOC, RWAXXX_A_TAU);
        (, address pip, , ) = RwaLiquidationOracleAbstract(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Init RWAXXX in Vat
        Initializable(MCD_VAT).init(ilk);
        // Init RWAXXX in Jug
        Initializable(MCD_JUG).init(ilk);

        // Allow RWAXXX Join to modify Vat registry
        DssExecLib.authorize(MCD_VAT, MCD_JOIN_RWAXXX_A);

        // 1m debt ceiling
        DssExecLib.increaseIlkDebtCeiling(ilk, RWAXXX_A_LINE, /* _global = */ true);

        // Set price feed for RWAXXX
        DssExecLib.setContract(MCD_SPOT, ilk, "pip", pip);

        // Set collateralization ratio
        DssExecLib.setIlkLiquidationRatio(ilk, RWAXXX_A_MAT);

        // Poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // Give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWAXXX_A, RWAXXX_A_URN);

        // MCD_PAUSE_PROXY and OPERATOR permission on URN
        RwaUrnAbstract(RWAXXX_A_URN).hope(address(this));
        RwaUrnAbstract(RWAXXX_A_URN).hope(address(RWAXXX_A_OPERATOR));

        // MCD_PAUSE_PROXY and Monetalis permission on RWAXXX_A_OUTPUT_CONDUIT
        RwaOutputConduit3Abstract(RWAXXX_A_OUTPUT_CONDUIT).hope(address(this));
        RwaOutputConduit3Abstract(RWAXXX_A_OUTPUT_CONDUIT).mate(address(this));
        RwaOutputConduit3Abstract(RWAXXX_A_OUTPUT_CONDUIT).hope(RWAXXX_A_OPERATOR);
        RwaOutputConduit3Abstract(RWAXXX_A_OUTPUT_CONDUIT).mate(RWAXXX_A_OPERATOR);
        // Coinbase custody whitelist for URN destination address
        RwaOutputConduit3Abstract(RWAXXX_A_OUTPUT_CONDUIT).kiss(address(RWAXXX_A_CUSTODY));
        // Set "quitTo" address for RWAXXX_A_OUTPUT_CONDUIT
        RwaOutputConduit3Abstract(RWAXXX_A_OUTPUT_CONDUIT).file("quitTo", RWAXXX_A_URN);

        // MCD_PAUSE_PROXY and Monetalis permission on RWAXXX_A_INPUT_CONDUIT_URN
        RwaInputConduit3Abstract(RWAXXX_A_INPUT_CONDUIT).mate(address(this));
        RwaInputConduit3Abstract(RWAXXX_A_INPUT_CONDUIT).mate(RWAXXX_A_OPERATOR);
        // Set "quitTo" address for RWAXXX_A_INPUT_CONDUIT_URN
        RwaInputConduit3Abstract(RWAXXX_A_INPUT_CONDUIT).file("quitTo", RWAXXX_A_CUSTODY);

        // Uncomment if the requires uses a PSM to swap Dai into another token.
        // MCD_PAUSE_PROXY and Operator permission on RWAXXX_A_INPUT_CONDUIT_JAR
        // RwaInputConduitAbstract(RWAXXX_A_INPUT_CONDUIT_JAR).mate(address(this));
        // RwaInputConduit3Abstract(RWAXXX_A_INPUT_CONDUIT_JAR).mate(RWAXXX_A_OPERATOR);
        // Set "quitTo" address for RWAXXX_A_INPUT_CONDUIT_JAR
        // RwaInputConduit3Abstract(RWAXXX_A_INPUT_CONDUIT_JAR).file("quitTo", RWAXXX_A_CUSTODY);

        // Add RWAXXX contract to the changelog
        DssExecLib.setChangelogAddress("RWAXXX",                     RWAXXX);
        DssExecLib.setChangelogAddress("PIP_RWAXXX",                 pip);
        DssExecLib.setChangelogAddress("MCD_JOIN_RWAXXX_A",          MCD_JOIN_RWAXXX_A);
        DssExecLib.setChangelogAddress("RWAXXX_A_URN",               RWAXXX_A_URN);
        DssExecLib.setChangelogAddress("RWAXXX_A_JAR",               RWAXXX_A_JAR);
        DssExecLib.setChangelogAddress("RWAXXX_A_INPUT_CONDUIT_URN", RWAXXX_A_INPUT_CONDUIT);
        // Uncomment if the requires uses a PSM to swap Dai into another token.
        // DssExecLib.setChangelogAddress("RWAXXX_A_INPUT_CONDUIT_JAR", RWAXXX_A_INPUT_CONDUIT_JAR);
        DssExecLib.setChangelogAddress("RWAXXX_A_OUTPUT_CONDUIT",    RWAXXX_A_OUTPUT_CONDUIT);

        // Add RWAXXX to ILK REGISTRY
        REGISTRY.put(
            ilk,
            MCD_JOIN_RWAXXX_A,
            RWAXXX,
            decimals,
            REG_CLASS_RWA,
            pip,
            address(0),
            "RWAXXX-A: TODO",
            GemAbstract(RWAXXX).symbol()
        );
    }

    function collateralAction() internal {
        IlkRegistryAbstract REGISTRY     = IlkRegistryAbstract(DssExecLib.reg());
        address MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
        // Uncomment this if the deal require a PSM for swapping Dai into another token.
        // address MCD_PSM_USDC_A           = DssExecLib.getChangelogAddress("MCD_PSM_USDC_A");
        address MCD_VAT                  = DssExecLib.vat();
        address MCD_JUG                  = DssExecLib.jug();
        address MCD_SPOT                 = DssExecLib.spotter();
        address MCD_JOIN_DAI             = DssExecLib.daiJoin();

        // --------------------------- RWA Collateral onboarding ---------------------------

        // Onboard *: https://vote.makerdao.com/polling/TODO
        onboardRwaXXX(REGISTRY, MIP21_LIQUIDATION_ORACLE, MCD_VAT, MCD_JUG, MCD_SPOT, MCD_JOIN_DAI /* , MCD_PSM_XXXX_A */);
    }
}
