# Wrapped Trillion Cycles (WTC)

WTC is a wrapped form of native ICP cycles, where 1WTC is equal to 1T cycles. This canister utilizes the EXT token standard with additional calls to facilitate the minting and conversion of WTC and cycles. This is current live and can be viewed here: [WTC Token](https://dsneu-dyaaa-aaaad-qagwa-cai.ic.fleek.co/)

In theory, WTC should maintain a stable value of 1XDR and therefore can be used as a stablecoin

## Minting
Tokens can be minted by sending ICP directly to our Minter to be converted to WTC (WIP), or by sending cycles to our token canister. You can read more about it [here](MINTING.md).

## Burning/Claiming/Converting back to cycles
WTC can be returned and converted back to cycles via a transfer call, or using the more advanced `burn` call. You can read more about it [here](CLAIMING.md).

## Testing
Following might be out dated, be warned

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
## TODO
- Better protection for callbacks not accepting all cycles (e.g. check refunded amount)
- Look into min threshold
- Move cycles to storage canisters for better control
