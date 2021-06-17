# Wrapped Trillion Cycles (WTC)

WTC is a wrapped form of native ICP cycles, where 1WTC is equal to 1T cycles. This canister utilizes the [EXT token standard](https://github.com/Toniq-Labs/extendable-token/blob/main/README.md) with additional calls to facilitate the minting and conversion of WTC and cycles. This is current live and can be viewed here: [WTC Token](https://dsneu-dyaaa-aaaad-qagwa-cai.ic.fleek.co/)

In theory, WTC should maintain a stable value of 1XDR and therefore can be used as a stablecoin

## Minting
Tokens can be minted by sending ICP directly to our Minter to be converted to WTC (WIP), or by sending cycles to our token canister. You can read more about it [here](MINTING.md).

## Burning/Claiming/Converting back to cycles
WTC can be returned and converted back to cycles via a transfer call, or using the more advanced `burn` call. You can read more about it [here](CLAIMING.md).

## Testing
If you are running this locally

```bash
//Clean start (if you want)
dfx start --clean --background

//Set identity if you need to
dfx identity new me && dfx identity use me

//Deploy all
dfx deploy --all

//Set WIC Canister ID and test canister
WTCCAN=$(dfx canister id wtc)

//Check current balances
dfx canister call $WTCCAN balances

//Mint some WIC from cycles wallet (1T cycles == 1WIC)
dfx canister --no-wallet call $(dfx identity get-wallet) wallet_call "(record { canister = principal \"$WTCCAN\"; method_name = \"mint\"; args = blob \"DIDL\00\01\7f\"; cycles = (1_000_000_000_000:nat64); } )"

//Check new balance
dfx canister call $WTCCAN balances

//Burn WIC and send to WICCAN canister. 
dfx canister call $WTCCAN burn "(500_000_000_000:nat, (func \"$WTCCAN\".acceptCycles))"

//Check balances again
dfx canister call $WTCCAN balances
```
## TODO
- Testing and review
