# Minting
Minting can be performed by sending cycles to the WTC token canister, which is then stored and minted into WTC, or by sending ICP to a Minter (which converts it to cycles, then forwards it to the WTC canister to turn mint WTC tokens).

## Sending cycles to mint WTC

Currently the only way to do this is via the command line using your cycles wallet. You must have dfx installed, as well as DIDC which can be installed as follows:
```
wget -O $HOME/bin/didc https://github.com/dfinity/candid/releases/download/2021-05-03/didc-linux64
chmod +x $HOME/bin/didc
```

You can mint WTC for either a standard address or a principal as follows:
```
//Send 1T cycles to address
TO_ADDRESS="8ad39e4f6347f960d5acf2a8b5307c3b40d66a265539c06ca073594c95a57049"
CYCLES="1_000_000_000_000"
ARG=
dfx canister --network ic --no-wallet call $(dfx identity --network ic get-wallet) wallet_call "(record { canister = principal \"5ymop-yyaaa-aaaah-qaa4q-cai\"; method_name = \"mint\"; args = $(didc encode '(opt variant { address = "'$TO_ADDRESS'" })' -f blob); cycles = ($CYCLES:nat64); } )"

//Send 1T to principal
TO_PRINCIPAL="sensj-ihxp6-tyvl7-7zwvj-fr42h-7ojjp-n7kxk-z6tvo-vxykp-umhfk-wqe"
CYCLES="1_000_000_000_000"
dfx canister --network ic --no-wallet call $(dfx identity --network ic get-wallet) wallet_call "(record { canister = principal \"5ymop-yyaaa-aaaah-qaa4q-cai\"; method_name = \"mint\"; args = $(didc encode '(opt variant { "principal" = principal "'$TO_PRINCIPAL'" })' -f blob); cycles = ($CYCLES:nat64); } )"
```

## Sending ICP to our Minter

We are currently waiting to be approved to send ICP from out smart canister, which is required to complete this method. We hope to have this available in the near future.
