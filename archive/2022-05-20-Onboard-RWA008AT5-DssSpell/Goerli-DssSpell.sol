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
// Enable ABIEncoderV2 when onboarding collateral
pragma experimental ABIEncoderV2;
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "dss-interfaces/dss/ChainlogAbstract.sol";
import "dss-interfaces/dss/VatAbstract.sol";

import { DssSpellCollateralOnboardingAction } from "./Goerli-DssSpellCollateralOnboarding.sol";

interface MateLike {
    function mate(address) external;
}

contract DssSpellAction is DssAction/*, DssSpellCollateralOnboardingAction*/ {
    // Provides a descriptive tag for bot consumption
    string public constant override description = "Goerli Spell";

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // ChainlogAbstract CHAINLOG = ChainlogAbstract(DssExecLib.LOG);

        // onboardNewCollaterals();
        // DssExecLib.setChangelogVersion("0.3.4");
        address RWA008AT4_A_INPUT_CONDUIT = 0x6f4719E6F2Df070a8B37F27b669106ee8dEE9606;
        address RWA008AT4_A_OUTPUT_CONDUIT = 0xe165cc177dA93b70802aD7f4FCaCa675F4234316;
        address DIIS_GROUP_WALLET = 0xb9444802F0831A3EB9f90E24EFe5FfA20138d684;

        MateLike(RWA008AT4_A_INPUT_CONDUIT).mate(DIIS_GROUP_WALLET);
        MateLike(RWA008AT4_A_OUTPUT_CONDUIT).mate(DIIS_GROUP_WALLET);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
