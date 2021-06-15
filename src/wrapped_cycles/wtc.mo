import Cycles "mo:base/ExperimentalCycles";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import AID "./util/AccountIdentifier";
import ExtCore "./ext/Core";
import ExtCommon "./ext/Common";
import ExtSecure "./ext/Secure";

actor WTC_Token {
  
  // Types
  // inherit from ext
  type AccountIdentifier = AID.AccountIdentifier;
  type SubAccount = AID.SubAccount;
  type User = ExtCore.User;
  type Balance = ExtCore.Balance;
  type TokenIdentifier = ExtCore.TokenIdentifier;
  type Extension = ExtCore.Extension;
  type Memo = ExtCore.Memo;
  type NotifyService = ExtCore.NotifyService;
  
  type BalanceRequest = ExtCore.BalanceRequest;
  type BalanceResponse = ExtCore.BalanceResponse;
  type TransferRequest = ExtCore.TransferRequest;
  type TransferResponse = ExtCore.TransferResponse;
  
  // wtc types
  type Callback = shared () -> async ();
  
  //Init variables
  private stable let METADATA : Metadata = {
    name : "Wrapped Trillion Cycles";
    symbol : "WTC";
    decimals : 12;
    metadata : [];
  }; 
  
  private let EXTENSIONS : [Extension] = ["@ext/common", "@ext/secure"];
  private let MINTING_FEE : Balance = 5_000_000;
  private let MIN_CYCLE_THRESHOLD : Balance = 2_000_000_000_000;

  private stable var _supply : Balance  = 0;
  private var _balances =  HashMap.HashMap<AccountIdentifier, Balance>(1, AID.equal, AID.hash);
  
  // WTC specific calls
  //To convert Cycles into WTC
  //You can use the cycle wallets `wallet_call` method
  public shared(msg) func mint(user : ?User) : async () {
    _assertCycles();
    let aid = switch (user) {
      case (?u) {
        _aidFromUser(user);
      };
      case (_) {
        AID.fromPrincipal(msg.caller, null);
      };
    };
    let amount = Cycles.available();
    assert(amount > 0);
    let accepted = Cycles.accept(amount);
    assert(accepted == amount);
    let new_balance = switch (_balances.get(aid)) {
      case (?balance) {
        balance + amount;
      };
      case (_) {
        amount;
      };
    };
    _balances.put(aid, new_balance);
    _supply += amount;
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
  public shared(msg) func burn(amount : Balance, callback : Callback) : async Bool {
    _assertCycles();
    let aid = AID.fromPrincipal(msg.caller, null);
    switch (balances.get(aid)) {
      case (?balance) {
        assert (amount <= balance);
        Cycles.add(amount);
        await callback();
        let refund = Cycles.refunded();
        let delta : Balance = (amount - refund);
        assert(delta > 0);
        let new_balance : Balance = balance - delta;
        assert(new_balance < balance);
        balances.put(aid, new_balance);
        _supply -= delta;
        return true;
      };
      case (_) {
        return false;
      };
    }
  };
  
  public query func minCyclesThreshold() : async Balance {
    return MIN_CYCLE_THRESHOLD;
  };
  public query func fee() : async Balance {
    return MINTING_FEE;
  };

  //Internal cycle management
  public func acceptCycles() : async () {
    let available = Cycles.available();
    let accepted = Cycles.accept(available);
    assert (accepted == available);
  };

  public query func availableCycles() : async Nat {
    assert(Cycles.balance() > _supply);
    return Cycles.balance() - _supply;
  };
  
  //ext specific calls
  //Update calls
  public shared(msg) func transfer(request: TransferRequest) : async TransferResponse {
    _assertCycles();
    let from_aid = AID.fromPrincipal(msg.caller, null);
    if (AID.equal(aid, _aidFromUser(request.from)) == false) {
      return #err(#Unauthorized);
    };
    let to_aid = AID.fromPrincipal(request.to, null);
    let amountAndFee : Balance = request.amount + request.fee;
    switch (balances.get(from_aid)) {
      case (?from_balance) {
        if (from_balance >= amountAndFee) {
          //Remove funds from sender first
          let from_balance_new : Balance = from_balance - amountAndFee;
          assert(from_balance_new <= from_balance);
          balances.put(from_aid, from_balance_new);
          
          //Fee is always consumed
          
          var accepted : Balance = request.amount;
          
          //Try and notify
          if (request.notify == true) {
            switch(request.user) {
              case (#address address) {
                //Refund and exit - can only notify principals
                _refund(from_aid, request.amount);
                return #err(#CannotNotify(address));
              };
              case (#principal principal) {
                let ns : NotifyService = actor(principal);
                accepted = switch(await ns.tokenTransferNotification()){
                  case (?b) b;
                  case (_) {
                    //Refund and exit
                    _refund(from_aid, request.amount);
                    return #err(#Rejected);
                  };
                };
              };
            };
          };
          assert(accepted <= request.amount); //Should never trigger...
          if (accepted < request.amount) {
            //There was a refund
            _refund(from_aid, request.amount - accepted);
          };
          
          //Add to new balance
          let to_balance_new = switch (balances.get(to_aid)) {
          case (?to_balance) {
              to_balance + accepted;
            };
          case (_) {
              accepted;
            };
          };
          assert(to_balance_new >= accepted); //Should never trigger...
          balances.put(to_aid, to_balance_new);
          return #ok(accepted);
        } else if (from_balance >= request.fee) {
          balances.put(aid, from_balance - request.fee);
          return #err(#InsufficientBalance);
        } else {
          balances.put(aid, 0);
          return #err(#InsufficientBalance);
        };
      };
      case (_) {
        return #err(#InsufficientBalance);
      };
    };
  };

  //ext-secure calls here
  public func extensions_secure() : async [Extension] {
    return extensions();
  };
  public func metadata_secure(token : TokenIdentifier) : async Result<Metadata, CommonError> {
    return metadata(token);
  };
  public func supply_secure(token : TokenIdentifier) : async Result<Balance, CommonError> {
    return supply(token);
  };
  public func balance_secure(request : BalanceRequest) : async BalanceResponse {
    return balance(request);
  };
    
  //Query calls
  public query func extensions() : async [Extension] {
    EXTENSIONS;
  };
  public query func balance(request : BalanceRequest) : async BalanceResponse {
    let aid = _aidFromUser(request.user);
    switch (balances.get(aid)) {
      case (?balance) {
        return #ok(balance);
      };
      case (_) {
        return #ok(0);
      };
    }
  };
  
  //ext-common queries
  //We don't have multiple tokens, so just use 0;
  public query func supply(token : TokenIdentifier) : async Result<Balance, CommonError> {
    #ok(_supply);
  };
  public query func metadata(token : TokenIdentifier) : async Result<Metadata, CommonError> {
    #ok(METADATA);
  };
  

  //Private
  //Ensure there are tokens available for computation
  private func _assertCycles() : () {
    assert( Cycles.balance() > (_supply + MIN_CYCLE_THRESHOLD) );
  };
  private func _aidFromUser(user : ?User) : AccountIdentifier {
    switch(user) {
      case (#address address) address;
      case (#principal principal) {
        AID.fromPrincipal(principal, null);
      };
    };
  };
  private func _refund(aid : AccountIdentifier, refund : Balance) : () {
    switch (balances.get(aid)) {
      case (?balance_now) {
        //Get updated balance incase it has changed after
        balances.put(aid, balance_now + refund);                        
      };
      case (_) {
        balances.put(aid, refund);                        
      };
    }
  };
}