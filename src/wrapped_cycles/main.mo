import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

actor WrappedCycles{

  type Callback = shared () -> async ();
  
  private stable let name_ : Text = "Wrapped ICP Cycles";
  private stable let decimals_ : Nat = 12;
  private stable let symbol_ : Text = "WIC";
  private stable var totalSupply_ : Nat  = 0;
  private var balances =  HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);
  private var allowances = HashMap.HashMap<Principal, HashMap.HashMap<Principal, Nat>>(1, Principal.equal, Principal.hash);
  
  //To convert Cycles into WIC
  //You can use the cycle wallets `wallet_call` method
  public shared(msg) func mint() : async () {
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
    public func accept() : async () {
      let available = Cycles.available();
      let accepted = Cycles.accept(available);
      assert (accepted == available);
    }
  */
  public shared(msg) func burn(amount : Nat, callback : Callback) : async Bool {
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
  
  //Helpers for testing - removing in final
  public shared(msg) func myBalance() : async Nat {
    switch (balances.get(msg.caller)) {
      case (?balance) {
        return balance;
      };
      case (_) {
        return 0;
      };
    }
  };
  public shared(msg) func whoami() : async Principal {
    return msg.caller;
  };
  public query func availableCycles() : async Nat {
    return Cycles.balance()
  };
  //This is to test burning without deploying a second canister. 
  //The user balance and total supply should decrease
  //but the available cycles will remain the same
  public func accept() : async () {
    let available = Cycles.available();
    let accepted = Cycles.accept(available);
    assert (accepted == available);
  };
}