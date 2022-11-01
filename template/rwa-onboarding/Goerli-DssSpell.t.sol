// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
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

import "./Goerli-DssSpell.t.base.sol";

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
    function gemJoin() external view returns (GemAbstract);
    function lock(uint256) external;
    function draw(uint256) external;
    function wipe(uint256) external;
    function free(uint256) external;
}

interface RwaOutputConduitLike {
    function can(address) external view returns (uint256);
    function may(address) external view returns (uint256);
    function gem() external view returns (GemAbstract);
    function bud(address) external view returns (uint256);
    function pick(address) external;
    function push() external;
    function push(uint256) external;
    function quit() external;
    function kiss(address) external;
    function mate(address) external;
    function hope(address) external;
    function quitTo() external view returns (address);
}

interface RwaInputConduitLike {
    function wards(address) external view returns (uint256);
    function may(address) external view returns (uint256);
    function quitTo() external view returns (address);
    function mate(address) external;
    function push() external;
}

contract DssSpellTest is GoerliDssSpellTestBase {
    function test_OSM_auth() private {  // make public to use
        // address ORACLE_WALLET01 = 0x4D6fbF888c374D7964D56144dE0C0cFBd49750D3;

        // validate the spell does what we told it to
        //bytes32[] memory ilks = reg.list();

        //for(uint256 i = 0; i < ilks.length; i++) {
        //    uint256 class = reg.class(ilks[i]);
        //    if (class != 1) { continue; }

        //    address pip = reg.pip(ilks[i]);
        //    // skip USDC, TUSD, PAXUSD, GUSD
        //    if (pip == 0x838212865E2c2f4F7226fCc0A3EFc3EB139eC661 ||
        //        pip == 0x0ce19eA2C568890e63083652f205554C927a0caa ||
        //        pip == 0xdF8474337c9D3f66C0b71d31C7D3596E4F517457 ||
        //        pip == 0x57A00620Ba1f5f81F20565ce72df4Ad695B389d7) {
        //        continue;
        //    }

        //    assertEq(OsmAbstract(pip).wards(ORACLE_WALLET01), 0);
        //}

        //vote(address(spell));
        //scheduleWaitAndCast(address(spell));
        //assertTrue(spell.done());

        //for(uint256 i = 0; i < ilks.length; i++) {
        //    uint256 class = reg.class(ilks[i]);
        //    if (class != 1) { continue; }

        //    address pip = reg.pip(ilks[i]);
        //    // skip USDC, TUSD, PAXUSD, GUSD
        //    if (pip == 0x838212865E2c2f4F7226fCc0A3EFc3EB139eC661 ||
        //        pip == 0x0ce19eA2C568890e63083652f205554C927a0caa ||
        //        pip == 0xdF8474337c9D3f66C0b71d31C7D3596E4F517457 ||
        //        pip == 0x57A00620Ba1f5f81F20565ce72df4Ad695B389d7) {
        //        continue;
        //    }

        //    assertEq(OsmAbstract(pip).wards(ORACLE_WALLET01), 1);
        //}
    }

    function test_oracle_list() private {  // make public to use
        // address ORACLE_WALLET01 = 0x4D6fbF888c374D7964D56144dE0C0cFBd49750D3;

        //assertEq(OsmAbstract(0xF15993A5C5BE496b8e1c9657Fd2233b579Cd3Bc6).wards(ORACLE_WALLET01), 0);

        //vote(address(spell));
        //scheduleWaitAndCast(address(spell));
        //assertTrue(spell.done());

        //assertEq(OsmAbstract(0xF15993A5C5BE496b8e1c9657Fd2233b579Cd3Bc6).wards(ORACLE_WALLET01), 1);
    }

    function testSpellIsCast_GENERAL() public {
        string memory description = new DssSpell().description();
        assertTrue(bytes(description).length > 0, "TestError/spell-description-length");
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
                stringToBytes32(description), "TestError/spell-description");

        if(address(spell) != address(spellValues.deployed_spell)) {
            assertEq(spell.expiration(), block.timestamp + spellValues.expiration_threshold, "TestError/spell-expiration");
        } else {
            assertEq(spell.expiration(), spellValues.deployed_spell_created + spellValues.expiration_threshold, "TestError/spell-expiration");

            // If the spell is deployed compare the on-chain bytecode size with the generated bytecode size.
            // extcodehash doesn't match, potentially because it's address-specific, avenue for further research.
            address depl_spell = spellValues.deployed_spell;
            address code_spell = address(new DssSpell());
            assertEq(getExtcodesize(depl_spell), getExtcodesize(code_spell), "TestError/spell-codesize");
        }

        assertTrue(spell.officeHours() == spellValues.office_hours_enabled, "TestError/spell-office-hours");

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        checkSystemValues(afterSpell);

        checkCollateralValues(afterSpell);
    }

    function testRemoveChainlogValues() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // try chainLog.getAddress("XXX") {
        //     assertTrue(false);
        // } catch Error(string memory errmsg) {
        //     assertTrue(cmpStr(errmsg, "dss-chain-log/invalid-key"));
        // } catch {
        //     assertTrue(false);
        // }

    }

    function testCollateralIntegrations() private {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new collateral tests here
        // checkIlkIntegration(
        //     "TOKEN-X",
        //     GemJoinAbstract(addr.addr("MCD_JOIN_TOKEN_X")),
        //     ClipAbstract(addr.addr("MCD_CLIP_TOKEN_X")),
        //     addr.addr("PIP_TOKEN"),
        //     true,
        //     true,
        //     false
        // );


    }

    function testLerpSurplusBuffer() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Insert new SB lerp tests here

        LerpAbstract lerp = LerpAbstract(lerpFactory.lerps("NAME"));

        uint256 duration = 210 days;
        hevm.warp(block.timestamp + duration / 2);
        assertEq(vow.hump(), 60 * MILLION * RAD);
        lerp.tick();
        assertEq(vow.hump(), 75 * MILLION * RAD);
        hevm.warp(block.timestamp + duration / 2);
        lerp.tick();
        assertEq(vow.hump(), 90 * MILLION * RAD);
        assertTrue(lerp.done());
    }

    function testNewChainlogValues() public { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // RWAXXX
        checkChainlogKey("RWAXXX_A_JAR");
        checkChainlogKey("RWAXXX");
        checkChainlogKey("MCD_JOIN_RWAXXX_A");
        checkChainlogKey("RWAXXX_A_URN");
        checkChainlogKey("RWAXXX_A_INPUT_CONDUIT_URN");
        checkChainlogKey("RWAXXX_A_INPUT_CONDUIT_JAR");
        checkChainlogKey("RWAXXX_A_OUTPUT_CONDUIT");
        checkChainlogKey("PIP_RWAXXX");

        checkChainlogVersion("1.14.2");
    }

    function testNewIlkRegistryValues() public { // make private to disable
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // RWAXXX
        assertEq(reg.pos("RWAXXX-A"),    53);
        assertEq(reg.join("RWAXXX-A"),   addr.addr("MCD_JOIN_RWAXXX_A"));
        assertEq(reg.gem("RWAXXX-A"),    addr.addr("RWAXXX"));
        assertEq(reg.dec("RWAXXX-A"),    GemAbstract(addr.addr("RWAXXX")).decimals());
        assertEq(reg.class("RWAXXX-A"),  3);
        assertEq(reg.pip("RWAXXX-A"),    addr.addr("PIP_RWAXXX"));
        assertEq(reg.name("RWAXXX-A"),   "RWAXXX-A: TODO");
        assertEq(reg.symbol("RWAXXX-A"), GemAbstract(addr.addr("RWAXXX")).symbol());
    }

    function testFailWrongDay() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailDay();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooEarly() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailEarly();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooLate() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailLate();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testOnTime() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
    }

    function testCastCost() public {
        vote(address(spell));
        spell.schedule();

        castPreviousSpell();
        hevm.warp(spell.nextCastTime());
        uint256 startGas = gasleft();
        spell.cast();
        uint256 endGas = gasleft();
        uint256 totalGas = startGas - endGas;

        assertTrue(spell.done());
        // Fail if cast is too expensive
        assertTrue(totalGas <= 10 * MILLION);
    }

    // The specific date doesn't matter that much since function is checking for difference between warps
    function test_nextCastTime() public {
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
        spell.schedule();

        uint256 monday_1400_UTC = 1606744800; // Nov 30, 2020
        uint256 monday_2100_UTC = 1606770000; // Nov 30, 2020

        // Day tests
        hevm.warp(monday_1400_UTC);                                    // Monday,   14:00 UTC
        assertEq(spell.nextCastTime(), monday_1400_UTC);               // Monday,   14:00 UTC

        if (spell.officeHours()) {
            hevm.warp(monday_1400_UTC - 1 days);                       // Sunday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_1400_UTC - 2 days);                       // Saturday, 14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_1400_UTC - 3 days);                       // Friday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC - 3 days);  // Able to cast

            hevm.warp(monday_2100_UTC);                                // Monday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC + 1 days);  // Tuesday,  14:00 UTC

            hevm.warp(monday_2100_UTC - 1 days);                       // Sunday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_2100_UTC - 2 days);                       // Saturday, 21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_2100_UTC - 3 days);                       // Friday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            // Time tests
            uint256 castTime;

            for(uint256 i = 0; i < 5; i++) {
                castTime = monday_1400_UTC + i * 1 days; // Next day at 14:00 UTC
                hevm.warp(castTime - 1 seconds); // 13:59:59 UTC
                assertEq(spell.nextCastTime(), castTime);

                hevm.warp(castTime + 7 hours + 1 seconds); // 21:00:01 UTC
                if (i < 4) {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + (i + 1) * 1 days); // Next day at 14:00 UTC
                } else {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + 7 days); // Next monday at 14:00 UTC (friday case)
                }
            }
        }
    }

    function testFail_notScheduled() public view {
        spell.nextCastTime();
    }

    function test_use_eta() public {
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
        spell.schedule();

        uint256 castTime = spell.nextCastTime();
        assertEq(castTime, spell.eta());
    }

    function test_Medianizers() private { // make public to use
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Track Median authorizations here
        address SET_TOKEN    = address(0);
        address TOKENUSD_MED = OsmAbstract(addr.addr("PIP_TOKEN")).src();
        assertEq(MedianAbstract(TOKENUSD_MED).bud(SET_TOKEN), 1);
    }

    function test_auth() public {
        checkAuth(false);
    }

    function test_auth_in_sources() public {
        checkAuth(true);
    }

    // Verifies that the bytecode of the action of the spell used for testing
    // matches what we'd expect.
    //
    // Not a complete replacement for Etherscan verification, unfortunately.
    // This is because the DssSpell bytecode is non-deterministic because it
    // deploys the action in its constructor and incorporates the action
    // address as an immutable variable--but the action address depends on the
    // address of the DssSpell which depends on the address+nonce of the
    // deploying address. If we had a way to simulate a contract creation by
    // an arbitrary address+nonce, we could verify the bytecode of the DssSpell
    // instead.
    //
    // Vacuous until the deployed_spell value is non-zero.
    function test_bytecode_matches() public {
        address expectedAction = (new DssSpell()).action();
        address actualAction   = spell.action();
        uint256 expectedBytecodeSize;
        uint256 actualBytecodeSize;
        assembly {
            expectedBytecodeSize := extcodesize(expectedAction)
            actualBytecodeSize   := extcodesize(actualAction)
        }

        uint256 metadataLength = getBytecodeMetadataLength(expectedAction);
        assertTrue(metadataLength <= expectedBytecodeSize);
        expectedBytecodeSize -= metadataLength;

        metadataLength = getBytecodeMetadataLength(actualAction);
        assertTrue(metadataLength <= actualBytecodeSize);
        actualBytecodeSize -= metadataLength;

        assertEq(actualBytecodeSize, expectedBytecodeSize);
        uint256 size = actualBytecodeSize;
        uint256 expectedHash;
        uint256 actualHash;
        assembly {
            let ptr := mload(0x40)

            extcodecopy(expectedAction, ptr, 0, size)
            expectedHash := keccak256(ptr, size)

            extcodecopy(actualAction, ptr, 0, size)
            actualHash := keccak256(ptr, size)
        }
        assertEq(expectedHash, actualHash);
    }

    // Validate addresses in test harness match chainlog
    function test_chainlog_values() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        for(uint256 i = 0; i < chainLog.count(); i++) {
            (bytes32 _key, address _val) = chainLog.get(i);
            assertEq(_val, addr.addr(_key), concat("TestError/chainlog-addr-mismatch-", _key));
        }
    }

    // Ensure version is updated if chainlog changes
    function test_chainlog_version_bump() public {

        uint256                   _count = chainLog.count();
        string    memory        _version = chainLog.version();
        address[] memory _chainlog_addrs = new address[](_count);

        for(uint256 i = 0; i < _count; i++) {
            (, address _val) = chainLog.get(i);
            _chainlog_addrs[i] = _val;
        }

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        if (keccak256(abi.encodePacked(_version)) == keccak256(abi.encodePacked(chainLog.version()))) {
            // Fail if the version is not updated and the chainlog count has changed
            if (_count != chainLog.count()) {
                emit log_named_string("Error", concat("TestError/chainlog-version-not-updated-count-change-", _version));
                fail();
                return;
            }
            // We are skipping this part of the test because we need to update the chainlog without bumping the version.

            // Fail if the chainlog is the same size but local keys don't match the chainlog.
            for(uint256 i = 0; i < _count; i++) {
                (, address _val) = chainLog.get(i);
                if (_chainlog_addrs[i] != _val) {
                    emit log_named_string("Error", concat("TestError/chainlog-version-not-updated-address-change-", _version));
                    fail();
                    return;
                }
            }
        }
    }

    function tryVest(address vest, uint256 id) internal returns (bool ok) {
        (ok,) = vest.call(abi.encodeWithSignature("vest(uint256)", id));
    }

    function testVestDAI() private { // make public to use
        VestAbstract vest = VestAbstract(addr.addr("MCD_VEST_DAI"));

        assertEq(vest.ids(), 0);

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vest.ids(), 1);

        assertEq(vest.cap(), 1 * MILLION * WAD / 30 days);

        assertEq(vest.usr(1), address(pauseProxy));
        assertEq(vest.bgn(1), block.timestamp - 1 days);
        assertEq(vest.clf(1), block.timestamp - 1 days);
        assertEq(vest.fin(1), block.timestamp);
        assertEq(vest.mgr(1), address(0));
        assertEq(vest.res(1), 0);
        assertEq(vest.tot(1), WAD);
        assertEq(vest.rxd(1), 0);

        uint256 prevBalance = dai.balanceOf(address(pauseProxy));
        assertTrue(tryVest(address(vest), 1));
        assertEq(dai.balanceOf(address(pauseProxy)), prevBalance + WAD);

        assertEq(vest.rxd(1), WAD);
    }

    // RWA tests
    address RWAXXX_A_OPERATOR                  = addr.addr("RWAXXX_A_OPERATOR");
    address RWAXXX_A_CUSTODY                   = addr.addr("RWAXXX_A_CUSTODY");
    
    RwaLiquidationLike oracle                  = RwaLiquidationLike(addr.addr("MIP21_LIQUIDATION_ORACLE"));

    GemAbstract          rwagem_XXX            = GemAbstract(addr.addr("RWAXXX"));
    GemJoinAbstract      rwajoin_XXX           = GemJoinAbstract(addr.addr("MCD_JOIN_RWAXXX_A"));
    RwaUrnLike           rwaurn_XXX            = RwaUrnLike(addr.addr("RWAXXX_A_URN"));
    RwaOutputConduitLike rwaconduitout_XXX     = RwaOutputConduitLike(addr.addr("RWAXXX_A_OUTPUT_CONDUIT"));
    GemAbstract          psmGem                = rwaconduitout_XXX.gem();
    RwaInputConduitLike  rwaconduitinurn_XXX   = RwaInputConduitLike(addr.addr("RWAXXX_A_INPUT_CONDUIT_URN"));
    RwaInputConduitLike  rwaconduitinjar_XXX   = RwaInputConduitLike(addr.addr("RWAXXX_A_INPUT_CONDUIT_JAR"));
    uint256 daiPsmGemDiffDecimals              = 10**sub(dai.decimals(), psmGem.decimals());

    function testRWAXXX_INTEGRATION_CONDUITS_SETUP() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(rwaconduitout_XXX.can(pauseProxy), 1, "OutputConduit/pause-proxy-not-operator");
        assertEq(rwaconduitout_XXX.can(RWAXXX_A_OPERATOR), 1, "OutputConduit/monetalis-not-operator");
        assertEq(rwaconduitout_XXX.may(pauseProxy), 1, "OutputConduit/pause-proxy-not-mate");
        assertEq(rwaconduitout_XXX.may(RWAXXX_A_OPERATOR), 1, "OutputConduit/monetalis-not-mate");
        assertEq(rwaconduitout_XXX.quitTo(), address(rwaurn_XXX), "OutputConduit/quit-to-not-urn");
        
        assertEq(rwaconduitout_XXX.bud(RWAXXX_A_CUSTODY), 1, "OutputConduit/coinbase-custody-not-whitelisted-for-pick");

        assertEq(rwaconduitinurn_XXX.may(pauseProxy), 1, "InputConduitUrn/pause-proxy-not-mate");
        assertEq(rwaconduitinurn_XXX.may(RWAXXX_A_OPERATOR), 1, "InputConduitUrn/monetalis-not-mate");
        assertEq(rwaconduitinurn_XXX.quitTo(), RWAXXX_A_CUSTODY, "InputConduitUrn/quit-to-not-set");

        assertEq(rwaconduitinjar_XXX.may(pauseProxy), 1, "InputConduitJar/pause-proxy-not-mate");
        assertEq(rwaconduitinjar_XXX.may(RWAXXX_A_OPERATOR), 1, "InputConduitJar/monetalis-not-mate");
        assertEq(rwaconduitinjar_XXX.quitTo(), RWAXXX_A_CUSTODY, "InputConduitJar/quit-to-not-set");

        assertEq(rwajoin_XXX.wards(address(rwaurn_XXX)), 1, "Join/ward-urn-not-set");

        assertEq(rwaurn_XXX.can(pauseProxy), 1, "Urn/pause-proxy-not-hoped");
        assertEq(rwaurn_XXX.can(RWAXXX_A_OPERATOR), 1, "Urn/operator-not-hoped");
    }

    function testRWAXXX_INTEGRATION_BUMP() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        giveAuth(address(oracle), address(this));

        (, address pip, , ) = oracle.ilks("RWAXXX-A");

        assertEq(DSValueAbstract(pip).read(), bytes32(250 * MILLION * WAD), "RWAXXX: Bad initial PIP value");

        oracle.bump("RWAXXX-A", 260 * MILLION * WAD);

        assertEq(DSValueAbstract(pip).read(), bytes32(260 * MILLION * WAD), "RWAXXX: Bad PIP value after bump()");
    }

    function testRWAXXX_INTEGRATION_TELL() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        giveAuth(address(vat), address(this));
        giveAuth(address(oracle), address(this));

        (, , , uint48 tocPre) = oracle.ilks("RWAXXX-A");
        assertEq(uint256(tocPre), 0, "RWAXXX: `toc` is not 0 before tell()");
        assertTrue(oracle.good("RWAXXX-A"), "RWAXXX: Oracle not good before tell()");

        vat.file("RWAXXX-A", "line", 0);
        oracle.tell("RWAXXX-A");

        (, , , uint48 tocPost) = oracle.ilks("RWAXXX-A");
        assertGt(uint256(tocPost), 0, "RWAXXX: `toc` is not set after tell()");
        assertTrue(!oracle.good("RWAXXX-A"), "RWAXXX: Oracle still good after tell()");
    }

    function testRWAXXX_INTEGRATION_TELL_CURE_GOOD() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        giveAuth(address(vat), address(this));
        giveAuth(address(oracle), address(this));

        vat.file("RWAXXX-A", "line", 0);
        oracle.tell("RWAXXX-A");

        assertTrue(!oracle.good("RWAXXX-A"), "RWAXXX: Oracle still good after tell()");

        oracle.cure("RWAXXX-A");

        assertTrue(oracle.good("RWAXXX-A"), "RWAXXX: Oracle not good after cure()");
        (, , , uint48 toc) = oracle.ilks("RWAXXX-A");
        assertEq(uint256(toc), 0, "RWAXXX: `toc` not zero after cure()");
    }

    function testFailRWAXXX_INTEGRATION_CURE_BEFORE_TELL() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        giveAuth(address(oracle), address(this));

        oracle.cure("RWAXXX-A");
    }

    function testRWAXXX_INTEGRATION_TELL_CULL() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        giveAuth(address(vat), address(this));
        giveAuth(address(oracle), address(this));

        assertTrue(oracle.good("RWAXXX-A"));

        vat.file("RWAXXX-A", "line", 0);
        oracle.tell("RWAXXX-A");

        assertTrue(!oracle.good("RWAXXX-A"), "RWAXXX: Oracle still good after tell()");

        oracle.cull("RWAXXX-A", addr.addr("RWAXXX_A_URN"));

        assertTrue(!oracle.good("RWAXXX-A"), "RWAXXX: Oracle still good after cull()");
        (, address pip, , ) = oracle.ilks("RWAXXX-A");
        assertEq(DSValueAbstract(pip).read(), bytes32(0), "RWAXXX: Oracle PIP value not set to zero after cull()");
    }

    function testRWAXXX_PAUSE_PROXY_OWNS_RWAXXX_TOKEN_BEFORE_SPELL() public {
        assertEq(rwagem_XXX.balanceOf(addr.addr('MCD_PAUSE_PROXY')), 1 * WAD);
    }

    function testRWAXXX_SPELL_LOCK_OPERATOR_DRAW_WIPE_FREE() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        uint256 drawAmount = 1_000_000 * WAD;

        // setting address(this) as operator
        hevm.store(address(rwaurn_XXX), keccak256(abi.encode(address(this), uint256(1))), bytes32(uint256(1)));
        assertEq(rwaurn_XXX.can(address(this)), 1);

        // Check if spell lock 1 * WAD of RWA009
        assertEq(rwagem_XXX.balanceOf(addr.addr('MCD_PAUSE_PROXY')), 0, "RWAXXX: gem not transfered from the pause proxy");
        assertEq(rwagem_XXX.balanceOf(address(rwajoin_XXX)), 1 * WAD, "RWAXXX: gem not locked into the urn");

        // 0 DAI in Output Conduit
        assertEq(dai.balanceOf(address(rwaconduitout_XXX)), 0, "RWAXXX: Dangling Dai in input conduit before draw()");

        // Draw 1mm
        rwaurn_XXX.draw(drawAmount);

        // 1mm DAI in Output Conduit
        assertEq(dai.balanceOf(address(rwaconduitout_XXX)), drawAmount, "RWAXXX: Dai drawn was not send to the recipient");

        (uint256 ink, uint256 art) = vat.urns("RWAXXX-A", address(rwaurn_XXX));
        assertEq(art, drawAmount, "RWAXXX: bad `art` after spell"); // DAI drawn == art as rate should always be 1 RAY
        assertEq(ink, 1 * WAD, "RWAXXX: bad `ink` after spell"); // Whole unit of collateral is locked

        hevm.warp(block.timestamp + 10 days);
        jug.drip("RWAXXX-A");

        (, uint256 rate,,,) = vat.ilks("RWAXXX-A");
        assertEq(rate, RAY, 'RWAXXX: bad `rate`'); // rate keeps being 1 RAY

        // wards
        giveAuth(address(rwaconduitout_XXX), address(this));
        // may
        rwaconduitout_XXX.mate(address(this));
        assertEq(rwaconduitout_XXX.may(address(this)), 1);
        rwaconduitout_XXX.hope(address(this));
        assertEq(rwaconduitout_XXX.can(address(this)), 1);

        rwaconduitout_XXX.kiss(address(this));
        assertEq(rwaconduitout_XXX.bud(address(this)), 1);
        rwaconduitout_XXX.pick(address(this));

        uint256 pushAmount = 100 * WAD; // We push only 100 DAI on Görli
        rwaconduitout_XXX.push(pushAmount);
        rwaconduitout_XXX.quit();

        assertEq(dai.balanceOf(address(rwaconduitout_XXX)), 0, "RWAXXX: Output conduit still holds Dai after quit()");
        assertEq(psmGem.balanceOf(address(this)), pushAmount / daiPsmGemDiffDecimals, "RWAXXX: Psm GEM not sent to destination after push()");
        assertEq(dai.balanceOf(address(rwaurn_XXX)), drawAmount - pushAmount, "RWAXXX: Dai not sent to destination after push()");

        // as we have SF 0 we need to pay exectly the same amount of DAI we have drawn
        uint256 daiToPay = drawAmount;

        // wards
        giveAuth(address(rwaconduitinurn_XXX), address(this));
        // may
        rwaconduitinurn_XXX.mate(address(this));
        assertEq(rwaconduitinurn_XXX.may(address(this)), 1);

        // transfer PSM GEM to input conduit
        psmGem.transfer(address(rwaconduitinurn_XXX), pushAmount / daiPsmGemDiffDecimals);
        assertEq(psmGem.balanceOf(address(rwaconduitinurn_XXX)), pushAmount / daiPsmGemDiffDecimals, "RWAXXX: Psm GEM not sent to input conduit");
        
        // input conduit 'push()' to the urn
        rwaconduitinurn_XXX.push();

        assertEq(dai.balanceOf(address(rwaurn_XXX)), daiToPay, "Balance of the URN doesnt match");

        // repay debt and free our collateral
        rwaurn_XXX.wipe(daiToPay);
        rwaurn_XXX.free(1 * WAD);

        // check if we get back RWA009 Tokens
        assertEq(rwagem_XXX.balanceOf(address(this)), 1 * WAD, "RWAXXX: gem not sent back to the caller");

        // check if we have 0 collateral and outstanding debt in the VAT
        (ink, art) = vat.urns("RWAXXX-A", address(rwaurn_XXX));
        assertEq(ink, 0, "RWAXXX: bad `ink` after free()");
        assertEq(art, 0, "RWAXXX: bad `art` after wipe()");
    }

    function testFailRWAXXX_DRAW_ABOVE_LINE() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        uint256 drawAmount = 2_000_000 * WAD;

        // setting address(this) as operator
        hevm.store(address(rwaurn_XXX), keccak256(abi.encode(address(this), uint256(1))), bytes32(uint256(1)));

        // Draw 2mm
        rwaurn_XXX.draw(drawAmount);
    }

    function testRWAXXX_OPERATOR_LOCK_DRAW_CAGE() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        uint256 drawAmount = 1_000_000 * WAD;

        // setting address(this) as operator
        hevm.store(address(rwaurn_XXX), keccak256(abi.encode(address(this), uint256(1))), bytes32(uint256(1)));
        assertEq(rwaurn_XXX.can(address(this)), 1);

        // Check if spell lock 1 * WAD of RWA009
        assertEq(rwagem_XXX.balanceOf(addr.addr('MCD_PAUSE_PROXY')), 0, "RWAXXX: gem not transfered from the pause proxy");
        assertEq(rwagem_XXX.balanceOf(address(rwajoin_XXX)), 1 * WAD, "RWAXXX: gem not locked into the urn");

        // 0 DAI in Output Conduit
        assertEq(dai.balanceOf(address(rwaconduitout_XXX)), 0, "RWAXXX: Dangling Dai in input conduit before draw()");

        // Draw 1mm
        rwaurn_XXX.draw(drawAmount);

        // 1mm DAI in Output Conduit
        assertEq(dai.balanceOf(address(rwaconduitout_XXX)), drawAmount, "RWAXXX: Dai drawn was not send to the recipient");

        (uint256 ink, uint256 art) = vat.urns("RWAXXX-A", address(rwaurn_XXX));
        assertEq(art, drawAmount, "RWAXXX: bad `art` after spell"); // DAI drawn == art as rate should always be 1 RAY
        assertEq(ink, 1 * WAD, "RWAXXX: bad `ink` after spell"); // Whole unit of collateral is locked

        hevm.warp(block.timestamp + 10 days);
        jug.drip("RWAXXX-A");

        (, uint256 rate,,,) = vat.ilks("RWAXXX-A");
        assertEq(rate, RAY, 'RWAXXX: bad `rate`'); // rate keeps being 1 RAY

        // wards
        giveAuth(address(rwaconduitout_XXX), address(this));
        // may
        rwaconduitout_XXX.mate(address(this));
        rwaconduitout_XXX.hope(address(this));

        rwaconduitout_XXX.kiss(address(this));
        assertEq(rwaconduitout_XXX.bud(address(this)), 1);
        rwaconduitout_XXX.pick(address(this));

        uint256 pushAmount = 100 * WAD; // We push only 100 DAI on Görli
        rwaconduitout_XXX.push(pushAmount);
        rwaconduitout_XXX.quit();

        assertEq(dai.balanceOf(address(rwaconduitout_XXX)), 0, "RWAXXX: Output conduit still holds Dai after quit()");
        assertEq(psmGem.balanceOf(address(this)), pushAmount / daiPsmGemDiffDecimals, "RWAXXX: Psm GEM not sent to destination after push()");
        assertEq(dai.balanceOf(address(rwaurn_XXX)), drawAmount - pushAmount, "RWAXXX: Dai not sent to destination after push()");

        // END
        giveAuth(address(end), address(this));
        end.cage();
        end.cage("RWAXXX-A");

        end.skim("RWAXXX-A", address(rwaurn_XXX));

        (ink, art) = vat.urns("RWAXXX-A", address(rwaurn_XXX));
        uint256 skimmedInk = drawAmount / 250_000_000;
        assertEq(ink, 1 * WAD - skimmedInk, "RWAXXX: wrong ink in urn after skim");
        assertEq(art, 0, "RWAXXX: wrong art in urn after skim");

        hevm.warp(block.timestamp + end.wait());

        // Removing the surplus to allow continuing the execution.  
        hevm.store(
            address(vat),
            keccak256(abi.encode(address(vow), uint256(5))),
            bytes32(uint256(0))
        );

        end.thaw();

        end.flow("RWAXXX-A");

        giveTokens(address(dai), 1_000_000 * WAD);
        dai.approve(address(daiJoin), 1_000_000 * WAD);
        daiJoin.join(address(this), 1_000_000 * WAD);

        vat.hope(address(end));
        end.pack(1_000_000 * WAD);

        // Check DAI redemption after "cage()"
        assertEq(vat.gem("RWAXXX-A", address(this)), 0, "RWAXXX: wrong vat gem");
        assertEq(rwagem_XXX.balanceOf(address(this)), 0, "RWAXXX: wrong gem balance");
        end.cash("RWAXXX-A", 1_000_000 * WAD);
        assertGt(vat.gem("RWAXXX-A", address(this)), 0, "RWAXXX: wrong vat gem after cash");
        assertEq(rwagem_XXX.balanceOf(address(this)), 0, "RWAXXX: wrong gem balance after cash");
        rwajoin_XXX.exit(address(this), vat.gem("RWAXXX-A", address(this)));
        assertEq(vat.gem("RWAXXX-A", address(this)), 0, "RWAXXX: wrong vat gem after exit");
        assertGt(rwagem_XXX.balanceOf(address(this)), 0, "RWAXXX: wrong gem balance after exit");
    }

    function testRWAXXX_SPELL_LOCK() public {
        (uint256 pink, uint256 part) = vat.urns("RWAXXX-A", address(rwaurn_XXX));
        uint256 prevBalance = rwagem_XXX.balanceOf(address(rwaurn_XXX.gemJoin()));

        assertEq(part, 0, "RWAXXX/bad-art-before-spell");
        assertEq(pink, 0, "RWAXXX/bad-ink-before-spell");

        uint256 lockAmount = 1 * WAD;

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Check if spell lock whole unit of RWAXXX Token to the Urn
        assertEq(rwagem_XXX.balanceOf(address(rwaurn_XXX.gemJoin())), prevBalance + lockAmount, "RWAXXX/spell-do-not-lock-rwaXXX-token");
        
        (uint256 ink, uint256 art) = vat.urns("RWAXXX-A", address(rwaurn_XXX));
        assertEq(art, 0, "RWAXXX/bad-art-after-spell");
        assertEq(ink, lockAmount, "RWAXXX/bad-ink-after-spell"); // Whole unit of collateral is locked
    }
}
