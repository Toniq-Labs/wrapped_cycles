import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

actor WrappedCycles{

  type Callback = shared () -> async ();
  type ICPTs = { e8s : Nat64 };
  type SubAccount = [Nat8];
  type AccountIdentifier = Text;
  type Memo = Nat64;
  type BlockHeight = Nat64;
  type TimeStamp = { timestamp_nanos : Nat64 };
  type TransactionNotification = {
    to : Principal;
    to_subaccount : ?SubAccount;
    from : Principal;
    memo : Memo;
    from_subaccount : ?SubAccount;
    amount : ICPTs;
    block_height : BlockHeight;
  };
  type NotifyCanisterArgs = {
    to_subaccount : ?SubAccount;
    from_subaccount : ?SubAccount;
    to_canister : Principal;
    max_fee : ICPTs;
    block_height : BlockHeight;
  };
  type SendArgs = {
    to : AccountIdentifier;
    fee : ICPTs;
    memo : Memo;
    from_subaccount : ?SubAccount;
    created_at_time : ?TimeStamp;
    amount : ICPTs;
  };
  type LedgerService = actor { 
    notify_dfx : shared NotifyCanisterArgs -> async ();
    send_dfx : shared SendArgs -> async BlockHeight;
  };
  type Result = { #Ok; #Err : Text };
  
  private let LEDGER : Principal = "";
  private let CYCLES_MINTER : Principal = "";
  private let MINFEE : ICPTs = { e8s = 10000};
  private let ZEROICP : ICPTs = { e8s = 0};
  private let MINT_FEE : Nat = 5_000_000;
  
  private stable let name_ : Text = "Wrapped Trillion Cycles";
  private stable let decimals_ : Nat = 12;
  private stable let symbol_ : Text = "WTC";
  //Threshold for min cycles required for computation
  private stable let minCyclesThreshold_ : Nat = 2_000_000_000_000;
  private stable var totalSupply_ : Nat  = 0;
  private var balances =  HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);
  private var allowances = HashMap.HashMap<Principal, HashMap.HashMap<Principal, Nat>>(1, Principal.equal, Principal.hash);
  
  //To convert ICP into WTC
  public shared(msg) func transaction_notification(tn : TransactionNotification) : async Result {
    //Check caller is ledger canister
    if(msg.caller != LEDGER) {
      return Error("");
    };
    //assert amount > min_amount for minting
    //assert amount > fee

    let ls : LedgerService = actor(LEDGER);

    //send ICP to minting canister
    let bh : BlockHeight = await ls.send_dfx({
      to = AID.fromPrincipal(CYCLES_MINTER, AID.cycles_subaccount(tn.to_canister));
      fee = MINFEE;
      memo = 1347768404;
      from_subaccount = tn.SubAccount;
      created_at_time = null;
      amount = ZEROICP;
    });
    //notify minting canister
    await ls.notify_dfx({
      to_subaccount = AID.cycles_subaccount(tn.to_canister);
      from_subaccount = tn.SubAccount;
      to_canister = CYCLES_MINTER;
      max_fee = MINFEE;
      block_height = bh;
    });
    //mint WTC
    
    
  }
  
  //To convert Cycles into WTC
  //You can use the cycle wallets `wallet_call` method
  public shared(msg) func mint() : async () {
    assert_cycles();
    let amount = Cycles.available();
    assert(amount > 0);
    let accepted = Cycles.accept(amount);
    assert(accepted == amount);
    var new_balance = switch (balances.get(msg.caller)) {
      case (?balance) {
        balance + amount;
      };
      case (_) {
        amount;
      };
    };
    balances.put(msg.caller, new_balance);
    totalSupply_ += amount;
  };
  
  /*
    Caller should submit a function to accept the cycles, e.g.:
    Callback function should be of type callback shared() -> async ()
    e.g. below:
    public func acceptCycles() : async () {
      let available = Cycles.available();
      let accepted = Cycles.accept(available);
      assert (accepted == available);
    };
  */
  public shared(msg) func burn(amount : Nat, callback : Callback) : async Bool {
    assert_cycles();
    switch (balances.get(msg.caller)) {
      case (?balance) {
        assert (amount <= balance);
        Cycles.add(amount);
        await callback();
        let refund = Cycles.refunded();
        let delta : Nat = (amount - refund);
        assert(delta > 0);
        let new_balance : Nat = balance - delta;
        assert(new_balance < balance);
        balances.put(msg.caller, new_balance);
        totalSupply_ -= delta;
        return true;
      };
      case (_) {
        return false;
      };
    }
  };
  
  //ERC20 TODO: Change based on standard approved by community
  public shared(msg) func transfer(to: Principal, value: Nat) : async Bool {
    assert_cycles();
    switch (balances.get(msg.caller)) {
      case (?from_balance) {
        if (from_balance >= value) {
          var from_balance_new : Nat = from_balance - value;
          assert(from_balance_new <= from_balance);
          balances.put(msg.caller, from_balance_new);
          var to_balance_new = switch (balances.get(to)) {
          case (?to_balance) {
              to_balance + value;
            };
          case (_) {
              value;
            };
          };
          assert(to_balance_new >= value);
          balances.put(to, to_balance_new);
          return true;
        } else {
          return false;
        };
      };
      case (_) {
        return false;
      };
    }
  };

  public shared(msg) func transferFrom(from: Principal, to: Principal, value: Nat) : async Bool {
    assert_cycles();
    switch (balances.get(from), allowances.get(from)) {
      case (?from_balance, ?allowance_from) {
        switch (allowance_from.get(msg.caller)) {
          case (?allowance) {
            if (from_balance >= value and allowance >= value) {
              var from_balance_new : Nat = from_balance - value;
              assert(from_balance_new <= from_balance);
              balances.put(from, from_balance_new);

              var to_balance_new = switch (balances.get(to)) {
              case (?to_balance) {
                  to_balance + value;
                };
              case (_) {
                  value;
                };
              };
              assert(to_balance_new >= value);
              balances.put(to, to_balance_new);

              var allowance_new : Nat = allowance - value;
              assert(allowance_new <= allowance);
              allowance_from.put(msg.caller, allowance_new);
              allowances.put(from, allowance_from);
              return true;                            
            } else {
              return false;
            };
          };
          case (_) {
            return false;
          };
        }
      };
      case (_) {
        return false;
      };
    }
  };

  public shared(msg) func approve(spender: Principal, value: Nat) : async Bool {
    assert_cycles();
    switch(allowances.get(msg.caller)) {
      case (?allowances_caller) {
        allowances_caller.put(spender, value);
        allowances.put(msg.caller, allowances_caller);
        return true;
      };
      case (_) {
        var temp = HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);
        temp.put(spender, value);
        allowances.put(msg.caller, temp);
        return true;
      };
    }
  };
  
  public query func balanceOf(who: Principal) : async Nat {
    switch (balances.get(who)) {
      case (?balance) {
        return balance;
      };
      case (_) {
        return 0;
      };
    }
  };

  public query func allowance(owner: Principal, spender: Principal) : async Nat {
    switch(allowances.get(owner)) {
      case (?allowance_owner) {
        switch(allowance_owner.get(spender)) {
          case (?allowance) {
            return allowance;
          };
          case (_) {
            return 0;
          };
        }
      };
      case (_) {
        return 0;
      };
    }
  };
  
  public query func totalSupply() : async Nat {
    return totalSupply_;
  };

  public query func name() : async Text {
    return name_;
  };

  public query func decimals() : async Nat {
    return decimals_;
  };

  public query func symbol() : async Text {
    return symbol_;
  };
  
  public query func minCyclesThreshold() : async Nat {
    return minCyclesThreshold_;
  };
  
    //Private
  //Ensure there are tokens available for computation
  private func assert_cycles() : () {
    assert( Cycles.balance() > (totalSupply_ + minCyclesThreshold_) );
  };
  
  //Internal cycle management
  public func acceptCycles() : async () {
    let available = Cycles.available();
    let accepted = Cycles.accept(available);
    assert (accepted == available);
  };

  public query func availableCycles() : async Nat {
    return Cycles.balance()
  };
}