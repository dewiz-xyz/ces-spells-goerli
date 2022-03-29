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

import "dss-exec-lib/DssExecLib.sol";
import "dss-interfaces/dss/ChainlogAbstract.sol";

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

    // --- Math ---
    uint256 constant BILLION = 10 ** 8;
    uint256 constant MILLION = 10 ** 6;
    uint256 constant RAY     = 10 ** 27;

    address constant DUMMY                 = 0x0EEb733A46e66e9dA6f8E96BF62fb7bA974A44e7;
    address constant PIP_DUMMY             = 0x8b648b13fcb0FB767A8E406ECF1071DFC3A46856;
    address constant MCD_JOIN_DUMMY_A      = 0x7F23a8550f038aC18Ba59442Eafeac1e0a19C759;
    address constant MCD_CLIP_DUMMY_A      = 0x9043b3529Ef841dE4D481ABED3243F366D220c68;
    address constant MCD_CLIP_CALC_DUMMY_A = 0x1Dc45AAB80636300ADF72Ec4b01e2868BFC9De83;

    // --- Math ---

    // --- DEPLOYED COLLATERAL ADDRESSES ---

    function onboardNewCollaterals() internal {
        // ----------------------------- Collateral onboarding -----------------------------
        //  Add ______________ as a new Vault Type
        //  Poll Link:

        DssExecLib.addNewCollateral(
            CollateralOpts({
                ilk:                  'DUMMY-A',
                gem:                  DUMMY,
                join:                 MCD_JOIN_DUMMY_A,
                clip:                 MCD_CLIP_DUMMY_A,
                calc:                 MCD_CLIP_CALC_DUMMY_A,
                pip:                  PIP_DUMMY,
                isLiquidatable:       false,
                isOSM:                false,
                whitelistOSM:         true,
                ilkDebtCeiling:       1000 * BILLION,
                minVaultAmount:       1000,
                maxLiquidationAmount: 3 * MILLION,
                liquidationPenalty:   1300,        // 13% penalty fee
                ilkStabilityFee:      ZERO_PCT_RATE,
                startingPriceFactor:  13000,       // Auction price begins at 130% of oracle
                breakerTolerance:     5000,        // Allows for a 50% hourly price drop before disabling liquidations
                auctionDuration:      140 minutes,
                permittedDrop:        4000,        // 40% price drop before reset
                liquidationRatio:     16000,       // 160% collateralization
                kprFlatReward:        300,         // 300 Dai
                kprPctReward:         10           // 0.1%
            })
        );

        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_DUMMY_A, 90 seconds, 9900);
        DssExecLib.setIlkAutoLineParameters('DUMMY-A', 100 * MILLION, 50 * MILLION, 1 hours);

        // ChainLog Updates
        // Add the new flip and join to the Chainlog
        address CHAINLOG = DssExecLib.LOG;
        ChainlogAbstract(CHAINLOG).setAddress("DUMMY", DUMMY);
        ChainlogAbstract(CHAINLOG).setAddress("PIP_DUMMY", PIP_DUMMY);
        ChainlogAbstract(CHAINLOG).setAddress("MCD_JOIN_DUMMY_A", MCD_JOIN_DUMMY_A);
        ChainlogAbstract(CHAINLOG).setAddress("MCD_CLIP_DUMMY_A", MCD_CLIP_DUMMY_A);
        ChainlogAbstract(CHAINLOG).setAddress("MCD_CLIP_CALC_DUMMY_A", MCD_CLIP_CALC_DUMMY_A);
        // ChainlogAbstract(CHAINLOG).setVersion("0.2.0");
    }
}
