# RWA Onboarding Spell

The following can be found in [`Goerli-DssSpellCollateralOnboarding.sol`](./Goerli-DssSpellCollateralOnboarding.sol):
- `RwaSpell`: which deploys and configures the RWA collateral in MakerDAO in accordance with MIP21.

The following can be found in [`Goerli-DssSpell.t.sol`](./Goerli-DssSpell.t.sol):

- `TellSpell`: which allows MakerDAO governance to initiate liquidation proceedings.
- `CureSpell`: which allows MakerDAO governance to dismiss liquidation proceedings.
- `CullSpell`: which allows MakerDAO governance to write off a loan which was in liquidation.
