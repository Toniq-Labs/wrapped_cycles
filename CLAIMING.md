
# Converting WTC into cycles

There are two methods to convert WTC tokens into cycles to be sent to a canister of your choosing:
1. Simple - simply "send" WTC to the canister you want to powerup and include a special memo
2. Advanced - send an API call to the token canister (usually done via dfx canister call)

The cycles are sent to your canister via a special callback which must accept the cycles (otherwise they are refunded).

## Receiving Cycles

Regardless of which method you choose, the receiving canister **must** contain a method to accept the cycles. If you choose the simple method, this callback must be named `acceptCycles`. The callback must be of the following type:

```
type Callback = shared () -> async ();
```

An example of this would be:
```
public func acceptCycles() : async () {
  let available = Cycles.available();
  let accepted = Cycles.accept(available);
  assert (accepted == available);
};
```

## Simple Method

To use the simple method you need to send the WTC directly to your canister's Principal using a special memo `0x6b646b6e7273`. Failing to set this memo will simply send the WTC to your canister as tokens, not as cycles. You must also ensure your canister has the correct `acceptCycles` update call included within it (as per above) - if this is not present, then your WTC will be lost and there won't be a way to retreive it.

You can do the above using Stoic - once the transaction completes, you should see your spent WTC has been used to topup your canister with an equal amount of cycles (minus fees). You do not need to be sending WTC from the controller of the canister.

## Advanced Method

To use the advanced method you need to send an API call which must come from the token holder's main address (not from a sub account). This can also be done via dfx:
```
//AMOUNT is the amount of cycles (not WTC, actual cycles e.g. 1WTC = 1_000_000_000_000 cycles)
//CANISTER_ID is the id of the canister receiving the cycles
//note acceptCycles can be different if the func is named differently
dfx canister --network ic call 5ymop-yyaaa-aaaah-qaa4q-cai burn "(AMOUNT:nat, (func \"CANISTER_ID\".acceptCycles
```
This method is more complex, but it allows for conversions to occur via other canisters and is more tailored to being used by developers. An example would be a canister holding a balance of WTC and being able to convert these to cycles when it is running low.
