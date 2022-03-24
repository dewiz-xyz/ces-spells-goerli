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

import { DssSpellCollateralOnboardingAction } from "./Goerli-DssSpellCollateralOnboarding.sol";

interface RelyLike {
    function rely(address) external;
}

contract DssSpellAction is DssAction /*, DssSpellCollateralOnboardingAction */ {
    // Provides a descriptive tag for bot consumption
    string public constant override description = "Goerli Spell";

    address internal constant MCD_JOIN_RWA008AT1_A = 0x95191eB3Ab5bEB48a3C0b1cd0E6d918931448a1E;

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        ChainlogAbstract CHAINLOG = ChainlogAbstract(DssExecLib.LOG);

        RelyLike(CHAINLOG.getAddress('MCD_VAT')).rely(MCD_JOIN_RWA008AT1_A);

        // onboardNewCollaterals();
        DssExecLib.setChangelogVersion("0.2.3");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
