/**

 */
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
//TODO pull in better
import AID "../util/AccountIdentifier";

module ExtCore = {
  public type AccountIdentifier = AID.AccountIdentifier;
  public type SubAccount = AID.SubAccount;
  public type User = {
    #address : AccountIdentifier; //No notification
    #principal : Principal; //defaults to sub account 0
  };
  public type Balance = Nat;
  public type TokenIdentifier  = Text;
  public type Extension = Text;
  public type Memo = Blob;
  public type NotifyService = actor { tokenTransferNotification : shared (TokenIdentifier, User, Balance, ?Memo) -> async ?Balance};
  public type CommonError = {
    #InvalidToken: TokenIdentifier;
    #Other : Text;
  };
  public type BalanceRequest = { 
    user : User; 
    token: TokenIdentifier;
  };
  public type BalanceResponse = Result.Result<Balance, CommonError>;

  public type TransferRequest = {
    from : User;
    to : User;
    token : TokenIdentifier;
    amount : Balance;
    memo : ?Memo;
    notify : Bool;
  };
  public type TransferResponse = Result.Result<Balance, {
    #Unauthorized;
    #InsufficientBalance;
    #Rejected; //Rejected by canister
    #InvalidToken: TokenIdentifier;
    #CannotNotify: AccountIdentifier;
    #Other : Text;
  }>;
  module User = {
    func equal(x : User, y : User) : Bool {
      let _x = switch(x) {
        case (#address address) address;
        case (#principal principal) {
          AID.fromPrincipal(principal, null);
        };
      };
      let _y = switch(y) {
        case (#address address) address;
        case (#principal principal) {
          AID.fromPrincipal(principal, null);
        };
      };
      return AID.equal(_x, _y);
    };
    func hash(x : User) : Hash.Hash {
      let _x = switch(x) {
        case (#address address) address;
        case (#principal principal) {
          AID.fromPrincipal(principal, null);
        };
      };
      return AID.hash(_x);
    };
  };
};