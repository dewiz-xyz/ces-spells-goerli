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

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

interface RwaUrnLike {
    function vat() external view returns(address);
    function jug() external view returns(address);
    function gemJoin() external view returns(address);
    function daiJoin() external view returns(address);
    function outputConduit() external view returns(address);
    function hope(address) external;
}

interface RwaJarLike {
    function chainlog() external view returns(address);
    function dai() external view returns(address);
    function daiJoin() external view returns(address);
}

interface RwaOutputConduitLike {
    function dai() external view returns(address);
    function gem() external view returns(address);
    function psm() external view returns(address);
    function file(bytes32 what, address data) external;
    function hope(address) external;
    function mate(address) external;
    function kiss(address) external;
}

interface RwaInputConduitLike {
    function dai() external view returns(address);
    function gem() external view returns(address);
    function psm() external view returns(address);
    function to() external view returns(address);
    function mate(address usr) external;
    function file(bytes32 what, address data) external;
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
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //

    // --- Math ---
    uint256 internal constant WAD = 10**18;

    // -- RWA999 MIP21 components --
    address internal constant RWA999                         = 0x0000000000000000000000000000000000000000; // TODO
    address internal constant MCD_JOIN_RWA999_A              = 0x0000000000000000000000000000000000000000; // TODO
    address internal constant RWA999_A_URN                   = 0x0000000000000000000000000000000000000000; // TODO
    address internal constant RWA999_A_JAR                   = 0x0000000000000000000000000000000000000000; // TODO
    address internal constant RWA999_A_OUTPUT_CONDUIT        = 0x0000000000000000000000000000000000000000; // TODO
    // Jar and URN Input Conduits
    address internal constant RWA999_A_INPUT_CONDUIT_URN     = 0x0000000000000000000000000000000000000000; // TODO
    address internal constant RWA999_A_INPUT_CONDUIT_JAR     = 0x0000000000000000000000000000000000000000; // TODO

    // MIP21_LIQUIDATION_ORACLE params

    // https://gateway.pinata.cloud/ipfs/TODO
    string  internal constant RWA999_DOC                     = "TODO";
    // There is no DssExecLib helper, so WAD precision is used.
    uint256 internal constant RWA999_A_INITIAL_PRICE         = 250_000_000 * WAD;
    uint48  internal constant RWA999_A_TAU                   = 0;

    // Ilk registry params
    uint256 internal constant RWA999_REG_CLASS_RWA           = 3;

    // Remaining params
    uint256 internal constant RWA999_A_LINE                  = 1_000_000;
    uint256 internal constant RWA999_A_MAT                   = 100_00; // 100% in basis-points

    // Operator address
    address internal constant RWA999_A_OPERATOR              = 0x0000000000000000000000000000000000000000; // TODO
    // Custody address
    address internal constant RWA999_A_CUSTODY               = 0x0000000000000000000000000000000000000000; // TODO

    // -- RWA999 END --

    function onboardRwa999(
        IlkRegistryAbstract REGISTRY,
        address MIP21_LIQUIDATION_ORACLE,
        address MCD_VAT,
        address MCD_JUG,
        address MCD_SPOT,
        address MCD_JOIN_DAI,
        address MCD_PSM_USDC_A
    ) internal {
        // RWA999-A collateral deploy
        bytes32 ilk      = "RWA999-A";
        uint256 decimals = GemAbstract(RWA999).decimals();

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA999_A).vat()                             == MCD_VAT,                                    "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA999_A).ilk()                             == ilk,                                        "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA999_A).gem()                             == RWA999,                                     "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA999_A).dec()                             == decimals,                                   "join-dec-not-match");

        require(RwaUrnLike(RWA999_A_URN).vat()                                       == MCD_VAT,                                    "urn-vat-not-match");
        require(RwaUrnLike(RWA999_A_URN).jug()                                       == MCD_JUG,                                    "urn-jug-not-match");
        require(RwaUrnLike(RWA999_A_URN).daiJoin()                                   == MCD_JOIN_DAI,                               "urn-daijoin-not-match");
        require(RwaUrnLike(RWA999_A_URN).gemJoin()                                   == MCD_JOIN_RWA999_A,                          "urn-gemjoin-not-match");
        require(RwaUrnLike(RWA999_A_URN).outputConduit()                             == RWA999_A_OUTPUT_CONDUIT,                    "urn-outputconduit-not-match");
        
        require(RwaJarLike(RWA999_A_JAR).chainlog()                                  == DssExecLib.LOG,                             "jar-chainlog-not-match");
        require(RwaJarLike(RWA999_A_JAR).dai()                                       == DssExecLib.dai(),                           "jar-dai-not-match");
        require(RwaJarLike(RWA999_A_JAR).daiJoin()                                   == MCD_JOIN_DAI,                               "jar-daijoin-not-match");

        require(RwaOutputConduitLike(RWA999_A_OUTPUT_CONDUIT).dai()                  == DssExecLib.dai(),                           "output-conduit-dai-not-match");
        require(RwaOutputConduitLike(RWA999_A_OUTPUT_CONDUIT).gem()                  == DssExecLib.getChangelogAddress("USDC"),     "output-conduit-gem-not-match");
        require(RwaOutputConduitLike(RWA999_A_OUTPUT_CONDUIT).psm()                  == MCD_PSM_USDC_A,                             "output-conduit-psm-not-match");
        
        require(RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_URN).psm()                == MCD_PSM_USDC_A,                             "input-conduit-urn-psm-not-match");
        require(RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_URN).to()                 == RWA999_A_URN,                               "input-conduit-urn-to-not-match");
        require(RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_URN).dai()                == DssExecLib.dai(),                           "input-conduit-urn-dai-not-match");
        require(RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_URN).gem()                == DssExecLib.getChangelogAddress("USDC"),     "input-conduit-urn-gem-not-match");

        require(RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_JAR).psm()                == MCD_PSM_USDC_A,                             "input-conduit-jar-psm-not-match");
        require(RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_JAR).to()                 == RWA999_A_JAR,                               "input-conduit-jar-to-not-match");
        require(RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_JAR).dai()                == DssExecLib.dai(),                           "input-conduit-jar-dai-not-match");
        require(RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_JAR).gem()                == DssExecLib.getChangelogAddress("USDC"),     "input-conduit-jar-gem-not-match");


        // Init the RwaLiquidationOracle
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(ilk, RWA999_A_INITIAL_PRICE, RWA999_DOC, RWA999_A_TAU);
        (, address pip, , ) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Init RWA999 in Vat
        Initializable(MCD_VAT).init(ilk);
        // Init RWA999 in Jug
        Initializable(MCD_JUG).init(ilk);

        // Allow RWA999 Join to modify Vat registry
        DssExecLib.authorize(MCD_VAT, MCD_JOIN_RWA999_A);

        // 1m debt ceiling
        DssExecLib.increaseIlkDebtCeiling(ilk, RWA999_A_LINE, /* _global = */ true);

        // Set price feed for RWA999
        DssExecLib.setContract(MCD_SPOT, ilk, "pip", pip);

        // Set collateralization ratio
        DssExecLib.setIlkLiquidationRatio(ilk, RWA999_A_MAT);

        // Poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // Give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA999_A, RWA999_A_URN);

        // MCD_PAUSE_PROXY and OPERATOR permission on URN
        RwaUrnLike(RWA999_A_URN).hope(address(this));
        RwaUrnLike(RWA999_A_URN).hope(address(RWA999_A_OPERATOR));

        // MCD_PAUSE_PROXY and Monetalis permission on RWA999_A_OUTPUT_CONDUIT
        RwaOutputConduitLike(RWA999_A_OUTPUT_CONDUIT).hope(address(this));
        RwaOutputConduitLike(RWA999_A_OUTPUT_CONDUIT).mate(address(this));
        RwaOutputConduitLike(RWA999_A_OUTPUT_CONDUIT).hope(RWA999_A_OPERATOR);
        RwaOutputConduitLike(RWA999_A_OUTPUT_CONDUIT).mate(RWA999_A_OPERATOR);
        // Coinbase custody whitelist for URN destination address
        RwaOutputConduitLike(RWA999_A_OUTPUT_CONDUIT).kiss(address(RWA999_A_CUSTODY));
        // Set "quitTo" address for RWA999_A_OUTPUT_CONDUIT
        RwaOutputConduitLike(RWA999_A_OUTPUT_CONDUIT).file("quitTo", RWA999_A_URN);

        // MCD_PAUSE_PROXY and Monetalis permission on RWA999_A_INPUT_CONDUIT_URN
        RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_URN).mate(address(this));
        RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_URN).mate(RWA999_A_OPERATOR);
        // Set "quitTo" address for RWA999_A_INPUT_CONDUIT_URN
        RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_URN).file("quitTo", RWA999_A_CUSTODY);

        // MCD_PAUSE_PROXY and Monetalis permission on RWA999_A_INPUT_CONDUIT_JAR
        RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_JAR).mate(address(this));
        RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_JAR).mate(RWA999_A_OPERATOR);
        // Set "quitTo" address for RWA999_A_INPUT_CONDUIT_JAR
        RwaInputConduitLike(RWA999_A_INPUT_CONDUIT_JAR).file("quitTo", RWA999_A_CUSTODY);

        // Add RWA999 contract to the changelog
        DssExecLib.setChangelogAddress("RWA999",                     RWA999);
        DssExecLib.setChangelogAddress("PIP_RWA999",                 pip);
        DssExecLib.setChangelogAddress("MCD_JOIN_RWA999_A",          MCD_JOIN_RWA999_A);
        DssExecLib.setChangelogAddress("RWA999_A_URN",               RWA999_A_URN);
        DssExecLib.setChangelogAddress("RWA999_A_JAR",               RWA999_A_JAR);
        DssExecLib.setChangelogAddress("RWA999_A_INPUT_CONDUIT_URN", RWA999_A_INPUT_CONDUIT_URN);
        DssExecLib.setChangelogAddress("RWA999_A_INPUT_CONDUIT_JAR", RWA999_A_INPUT_CONDUIT_JAR);
        DssExecLib.setChangelogAddress("RWA999_A_OUTPUT_CONDUIT",    RWA999_A_OUTPUT_CONDUIT);

        // Add RWA999 to ILK REGISTRY
        REGISTRY.put(
            ilk,
            MCD_JOIN_RWA999_A,
            RWA999,
            decimals,
            RWA999_REG_CLASS_RWA,
            pip,
            address(0),
            "RWA999-A: TODO",
            GemAbstract(RWA999).symbol()
        );
    }

    function onboardNewCollaterals() internal {
        IlkRegistryAbstract REGISTRY     = IlkRegistryAbstract(DssExecLib.reg());
        address MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
        address MCD_PSM_USDC_A           = DssExecLib.getChangelogAddress("MCD_PSM_USDC_A");
        address MCD_VAT                  = DssExecLib.vat();
        address MCD_JUG                  = DssExecLib.jug();
        address MCD_SPOT                 = DssExecLib.spotter();
        address MCD_JOIN_DAI             = DssExecLib.daiJoin();

        // --------------------------- RWA Collateral onboarding ---------------------------

        // Onboard *: https://vote.makerdao.com/polling/TODO
        onboardRwa999(REGISTRY, MIP21_LIQUIDATION_ORACLE, MCD_VAT, MCD_JUG, MCD_SPOT, MCD_JOIN_DAI, MCD_PSM_USDC_A);
    }
}
