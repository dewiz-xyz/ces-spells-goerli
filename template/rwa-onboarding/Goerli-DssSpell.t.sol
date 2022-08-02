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

import "./Goerli-DssSpell.t.base.sol";

contract DssSpellTest is GoerliDssSpellTestBase {
    // GOERLI ADDRESSES
    bytes32 constant ilk = "RWA999-A";

    DSTokenAbstract rwaGem             = DSTokenAbstract     (addr.addr("RWA999"));
    RwaLiquidationLike oracle          = RwaLiquidationLike  (addr.addr("MIP21_LIQUIDATION_ORACLE"));
    RwaUrnLike rwaUrn                  = RwaUrnLike          (addr.addr("RWA999_A_URN"));
    RwaInputConduitLike rwaConduitIn   = RwaInputConduitLike (addr.addr("RWA999_A_INPUT_CONDUIT"));
    RwaOutputConduitLike rwaConduitOut = RwaOutputConduitLike(addr.addr("RWA999_A_OUTPUT_CONDUIT"));

    BumpSpell bumpSpell;
    TellSpell tellSpell;
    CureSpell cureSpell;
    CullSpell cullSpell;
    EndSpell endSpell;

    function testCollateralIntegrations() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new collateral tests here
        checkIlkIntegration(
            "RWA999-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_RWA999_A")),
            ClipAbstract(addr.addr("MCD_CLIP_RWA999_A")),
            addr.addr("PIP_RWA999"),
            false,
            false,
            false
        );
    }

    function testNewChainlogValues() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // RWA999
        checkChainlogKey("RWA999");
        checkChainlogKey("PIP_RWA999");
        checkChainlogKey("MCD_JOIN_RWA999_A");
        checkChainlogKey("RWA999_A_URN");
        checkChainlogKey("RWA999_A_OUTPUT_CONDUIT");
        checkChainlogKey("RWA999_A_INPUT_CONDUIT");
    }

    function testNewIlkRegistryValues() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // RWA999
        (, address pip,,) = oracle.ilks("RWA999-A");

        assertEq(reg.pos   ("RWA999-A"), 50);
        assertEq(reg.join  ("RWA999-A"), addr.addr("MCD_JOIN_RWA999_A"));
        assertEq(reg.gem   ("RWA999-A"), addr.addr("RWA999"));
        assertEq(reg.dec   ("RWA999-A"), DSTokenAbstract(addr.addr("RWA999")).decimals());
        assertEq(reg.class ("RWA999-A"), 3);
        assertEq(reg.pip   ("RWA999-A"), pip);
        assertEq(reg.name  ("RWA999-A"), "RWA999-A: SG Forge OFH");
        assertEq(reg.symbol("RWA999-A"), "RWA999");
    }

    function testSpellIsCast_RWA999_INTEGRATION_BUMP() public {
        if (!spell.done()) {
            vote(address(spell));
            scheduleWaitAndCast(address(spell));
            assertTrue(spell.done());
        }

        bumpSpell = new BumpSpell();
        vote(address(bumpSpell));

        bumpSpell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);
        (, address pip, , ) = oracle.ilks("RWA999-A");

        assertEq(DSValueAbstract(pip).read(), bytes32(52_000_000 * WAD));
        bumpSpell.cast();
        assertEq(DSValueAbstract(pip).read(), bytes32(60_000_000 * WAD));
    }

    function testSpellIsCast_RWA999_INTEGRATION_TELL() public {
        if (!spell.done()) {
            vote(address(spell));
            scheduleWaitAndCast(address(spell));
            assertTrue(spell.done());
        }

        tellSpell = new TellSpell();
        vote(address(tellSpell));

        tellSpell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);

        (, , , uint48 tocPre) = oracle.ilks("RWA999-A");
        assertTrue(tocPre == 0);
        assertTrue(oracle.good("RWA999-A"));

        tellSpell.cast();

        (, , , uint48 tocPost) = oracle.ilks("RWA999-A");
        assertTrue(tocPost > 0);
        assertTrue(oracle.good("RWA999-A"));

        hevm.warp(block.timestamp + 2 weeks);
        assertTrue(!oracle.good("RWA999-A"));
    }

    function testSpellIsCast_RWA999_INTEGRATION_TELL_CURE_GOOD() public {
        if (!spell.done()) {
            vote(address(spell));
            scheduleWaitAndCast(address(spell));
            assertTrue(spell.done());
        }

        tellSpell = new TellSpell();
        vote(address(tellSpell));

        tellSpell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);

        tellSpell.cast();

        assertTrue(oracle.good(ilk));
        hevm.warp(block.timestamp + 2 weeks);
        assertTrue(!oracle.good(ilk));

        cureSpell = new CureSpell();
        vote(address(cureSpell));

        cureSpell.schedule();

        castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);

        cureSpell.cast();

        assertTrue(oracle.good(ilk));
        (, , , uint48 toc) = oracle.ilks(ilk);
        assertEq(uint256(toc), 0);
    }

    function testFailSpellIsCast_RWA999_INTEGRATION_CURE() public {
        if (!spell.done()) {
            vote(address(spell));
            scheduleWaitAndCast(address(spell));
            assertTrue(spell.done());
        }

        cureSpell = new CureSpell();
        vote(address(cureSpell));

        cureSpell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);

        cureSpell.cast();
    }

    function testSpellIsCast_RWA999_INTEGRATION_TELL_CULL() public {
        if (!spell.done()) {
            vote(address(spell));
            scheduleWaitAndCast(address(spell));
            assertTrue(spell.done());
        }
        assertTrue(oracle.good("RWA999-A"));

        tellSpell = new TellSpell();
        vote(address(tellSpell));

        tellSpell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);

        tellSpell.cast();

        assertTrue(oracle.good("RWA999-A"));
        hevm.warp(block.timestamp + 2 weeks);
        assertTrue(!oracle.good("RWA999-A"));

        cullSpell = new CullSpell();
        vote(address(cullSpell));

        cullSpell.schedule();

        castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);

        cullSpell.cast();

        assertTrue(!oracle.good("RWA999-A"));
        (, address pip, , ) = oracle.ilks("RWA999-A");
        assertEq(DSValueAbstract(pip).read(), bytes32(0));
    }

    function testSpellIsCast_RWA999_OPERATOR_LOCK_DRAW_CONDUITS_WIPE_FREE() public {
        if (!spell.done()) {
            vote(address(spell));
            scheduleWaitAndCast(address(spell));
            assertTrue(spell.done());
        }

        hevm.warp(now + 10 days); // Let rate be > 1

        // set the balance of this contract
        hevm.store(address(rwaGem), keccak256(abi.encode(address(this), uint256(3))), bytes32(uint256(2 * WAD)));
        // setting address(this) as operator
        hevm.store(address(rwaUrn), keccak256(abi.encode(address(this), uint256(1))), bytes32(uint256(1)));

        (uint256 preInk, uint256 preArt) = vat.urns(ilk, address(rwaUrn));

        assertEq(rwaGem.balanceOf(address(this)), 2 * WAD);
        assertEq(rwaUrn.can(address(this)), 1);

        rwaGem.approve(address(rwaUrn), 1 * WAD);
        rwaUrn.lock(1 * WAD);

        assertEq(dai.balanceOf(address(rwaConduitOut)), 0);
        rwaUrn.draw(1 * WAD);

        (, uint256 rate, , , ) = vat.ilks("RWA999-A");

        uint256 dustInVat = vat.dai(address(rwaUrn));

        (uint256 ink, uint256 art) = vat.urns(ilk, address(rwaUrn));
        assertEq(ink, 1 * WAD + preInk);
        uint256 currArt = ((1 * RAD + dustInVat) / rate) + preArt;

        assertTrue(art >= currArt - 2 && art <= currArt + 2); // approximation for vat rounding
        assertEq(dai.balanceOf(address(rwaConduitOut)), 1 * WAD);

        // wards
        hevm.store(address(rwaConduitOut), keccak256(abi.encode(address(this), uint256(0))), bytes32(uint256(1)));
        // can
        hevm.store(address(rwaConduitOut), keccak256(abi.encode(address(this), uint256(1))), bytes32(uint256(1)));
        // may
        hevm.store(address(rwaConduitOut), keccak256(abi.encode(address(this), uint256(6))), bytes32(uint256(1)));

        assertEq(dai.balanceOf(address(rwaConduitOut)), 1 * WAD);

        rwaConduitOut.pick(address(this));

        rwaConduitOut.push();

        assertEq(dai.balanceOf(address(rwaConduitOut)), 0);
        assertEq(dai.balanceOf(address(this)), 1 * WAD);

        hevm.warp(now + 10 days);

        (ink, art) = vat.urns(ilk, address(rwaUrn));
        assertEq(ink, 1 * WAD + preInk);

        currArt = ((1 * RAD + dustInVat) / rate) + preArt;
        assertTrue(art >= currArt - 2 && art <= currArt + 2); // approximation for vat rounding

        (ink, ) = vat.urns(ilk, address(this));
        assertEq(ink, 0);

        jug.drip("RWA999-A");

        (, rate, , , ) = vat.ilks("RWA999-A");

        uint256 daiToPay = (art * rate - dustInVat) / RAY + 1; // extra wei rounding
        uint256 vatDai = daiToPay * RAY;

        uint256 currentDaiSupply = dai.totalSupply();

        address MCD_JOIN_DAI = addr.addr("MCD_JOIN_DAI");

        // Forcing extra dai balance for MCD_JOIN_DAI on the Vat
        hevm.store(address(vat),          keccak256(abi.encode(MCD_JOIN_DAI, uint256(5))),  bytes32(vatDai));
        // Forcing extra DAI total supply to accomodate the accumulated fee
        hevm.store(address(dai),          bytes32(uint256(1)),                              bytes32(currentDaiSupply + (daiToPay - art)));
        // Forcing extra DAI balance to pay accumulated fee
        hevm.store(address(dai),          keccak256(abi.encode(address(this), uint256(2))), bytes32(daiToPay));
        // wards
        hevm.store(address(rwaConduitIn), keccak256(abi.encode(address(this), uint256(3))), bytes32(uint256(1)));
        // may
        hevm.store(address(rwaConduitIn), keccak256(abi.encode(address(this), uint256(4))), bytes32(uint256(1)));

        assertEq(dai.balanceOf(address(rwaConduitIn)), 0);

        dai.transfer(address(rwaConduitIn), daiToPay);
        assertEq(dai.balanceOf(address(rwaConduitIn)), daiToPay);

        rwaConduitIn.push();

        assertEq(dai.balanceOf(address(rwaUrn)),              daiToPay);
        assertEq(dai.balanceOf(address(rwaConduitIn)),        0);
        assertEq(vat.dai(address(addr.addr("MCD_JOIN_DAI"))), vatDai);

        rwaUrn.wipe(daiToPay);
        rwaUrn.free(1 * WAD);

        (ink, art) = vat.urns(ilk, address(rwaUrn));
        assertEq(ink, preInk);
        assertTrue(art < 4); // wad -> rad conversion in wipe leaves some dust

        (ink, ) = vat.urns(ilk, address(this));
        assertEq(ink, 0);
    }
}

contract TestSpell {
    DSPauseAbstract public pause;

    address public action;
    bytes32 public tag;
    uint256 public eta;
    bytes public sig;
    uint256 public expiration;
    bool public done;

    constructor() public {
        Addresses addr = new Addresses();

        pause = DSPauseAbstract(addr.addr("MCD_PAUSE"));
        sig   = abi.encodeWithSignature("execute()");
    }

    function setTag() internal {
        bytes32 _tag;
        address _action = action;
        assembly {
            _tag := extcodehash(_action)
        }
        tag = _tag;
    }

    function schedule() public {
        require(eta == 0, "This spell has already been scheduled");
        eta = block.timestamp + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

contract EndSpellAction {
    function execute() public {
        Addresses addr = new Addresses();

        EndAbstract(addr.addr("MCD_END")).cage();
    }
}

contract EndSpell is TestSpell {
    constructor() public {
        action = address(new EndSpellAction());
        setTag();
    }
}

contract CullSpellAction {
    bytes32 constant ilk = "RWA999-A";

    function execute() public {
        Addresses addr = new Addresses();

        RwaLiquidationLike(addr.addr("MIP21_LIQUIDATION_ORACLE")).cull(ilk, addr.addr("RWA999_A_URN"));
    }
}

contract CullSpell is TestSpell {
    constructor() public {
        action = address(new CullSpellAction());
        setTag();
    }
}

contract CureSpellAction {
    bytes32 constant ilk = "RWA999-A";

    function execute() public {
        Addresses addr = new Addresses();

        RwaLiquidationLike(addr.addr("MIP21_LIQUIDATION_ORACLE")).cure(ilk);
    }
}

contract CureSpell is TestSpell {
    constructor() public {
        action = address(new CureSpellAction());
        setTag();
    }
}

contract TellSpellAction {
    bytes32 constant ilk = "RWA999-A";

    function execute() public {
        Addresses addr = new Addresses();

        VatAbstract(addr.addr("MCD_VAT")).file(ilk, "line", 0);
        RwaLiquidationLike(addr.addr("MIP21_LIQUIDATION_ORACLE")).tell(ilk);
    }
}

contract TellSpell is TestSpell {
    constructor() public {
        action = address(new TellSpellAction());
        setTag();
    }
}

contract BumpSpellAction {
    bytes32 constant ilk     = "RWA999-A";
    uint256 constant WAD     = 10**18;

    function execute() public {
        Addresses addr = new Addresses();

        RwaLiquidationLike(addr.addr("MIP21_LIQUIDATION_ORACLE")).bump(ilk, 40_000_000 * WAD);
    }
}

contract BumpSpell is TestSpell {
    constructor() public {
        action = address(new BumpSpellAction());
        setTag();
    }
}

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (string memory, address, uint48 toc, uint48 tau);
    function bump(bytes32 ilk, uint256 val) external;
    function tell(bytes32) external;
    function cure(bytes32) external;
    function cull(bytes32, address) external;
    function good(bytes32) external view returns (bool);
}

interface RwaUrnLike {
    function can(address) external view returns (uint256);
    function lock(uint256) external;
    function draw(uint256) external;
    function wipe(uint256) external;
    function free(uint256) external;
}

interface RwaOutputConduitLike {
    function pick(address) external;
    function push() external;
}

interface RwaInputConduitLike {
    function push() external;
}
