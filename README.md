# Wrapped ICP Cycles (WIC)

Motoko canister code for wrapped ICP cycles as erc20 style tokens. This canister utilizes a standard ERC20 style token with additional "burn" and "mint" functions. We hope to deploy a version of this canister to the ICP as soon as we can.

In theory, WIC should essentially be a stablecoin (1WIC = 1XDR).

## Minting
Tokens are minted by using the cycles wallet `wallet_call` feature which allows us to forward cycles to the WIC canister which is converted to WIC (1T cycles = 1WIC). We can then continue to trade these tokens like any other token on exchanges.

## Burning
Tokens can be returned to the WIC canister via a burn mechanism, which then returns an equal amount of cycles to a user defined canister (1WIC = 1T cycles). This allows developers to easily purchase WIC from secondary markets and have it easily send to their canisters. To burn tokens, the user must provide a canister ID and method (the **callback** function) which can accept the returned cycles.

The callback must be of the following type:
```
type Callback = shared () -> async ();
```

An example function that can be included in your canister is as follows:
```
//Proposed standard to topup canisters
public func accept_cycles() : async () {
  let available = Cycles.available();
  let accepted = Cycles.accept(available);
  assert (accepted == available);
};
```
This can be submitted to the burn function in the following form:
```
//Where ryjl3-tyaaa-aaaaa-aaaba-cai is the principal/canister id of your canister
(func ryjl3-tyaaa-aaaaa-aaaba-cai.accept_cycles)
```

## Testing
We create two canisters, our WIC canister which handles the burning/minting/token logic and a test canister which can receive returned cycles (via burning).

```bash
//Clean start (if you want)
dfx start --clean --background

//Set identity if you need to
dfx identity new me && dfx identity use me

//Deploy all
dfx deploy --all

//Set WIC Canister ID and test canister
WICCAN=$(dfx canister id wrapped_cycles)
TESTCAN=$(dfx canister id test)

//Check available cycles in canister and current balance
dfx canister call $WICCAN availableCycles
dfx canister call $WICCAN myBalance

//Mint some WIC from cycles wallet (1T cycles == 1WIC)
dfx canister --no-wallet call $(dfx identity get-wallet) wallet_call "(record { canister = principal \"$WICCAN\"; method_name = \"mint\"; args = blob \"DIDL\00\00\"; cycles = (1_000_000_000_000:nat64); } )"

//Check new balance and available cycles (both should have increased by 1T)
dfx canister call $WICCAN myBalance
dfx canister call $WICCAN availableCycles

//Burn WIC and send to TEST canister. 
dfx canister call $TESTCAN availableCycles
dfx canister call $WICCAN burn "(500_000_000_000:nat, (func \"$TESTCAN\".accept_cycles))"

//Check balances again
dfx canister call $WICCAN myBalance
dfx canister call $TESTCAN availableCycles
dfx canister call $WICCAN availableCycles
```
