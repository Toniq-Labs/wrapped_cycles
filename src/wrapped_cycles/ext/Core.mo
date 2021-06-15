/**

 */
import Result "mo:base/Result";

module ExtCore = {
  public type AccountIdentifier = Text;
  public type SubAccount = [Nat8];
  public type User = {
    #address : AccountIdentifier; //No notification
    #principal : Principal; //defaults to sub account 0
  };
  public type Balance = Nat;
  public type TokenIdentifier  = Text;
  public type Extension = Text;
  public type Memo : Blob;
  public type NotifyService = actor { tokenTransferNotification : shared (TokenIdentifier, User, Balance, ?Memo) -> async ?Balance)};
  public type CommonError = {
    #InvalidToken: TokenIdentifier;
    #Other : Text;
  };
  public type BalanceRequest = { 
    user : User; 
    token: TokenIdentifier;
  };
  public type BalanceResponse = Result<Balance, CommonError>;

  public type TransferRequest = {
    from : User;
    to : User;
    token : TokenIdentifier;
    amount : Balance;
    memo : ?Memo;
    notify : Bool;
  };
  public type TransferResponse = Result<Balance, {
    #Unauthorized;
    #InsufficientBalance;
    #Rejected; //Rejected by canister
    #InvalidToken: TokenIdentifier;
    #CannotNotify: AccountIdentifier;
    #Other : Text;
  }>;
  module User = {
    public let equal = Principal.equal;
    public let hash = Principal.hash;
  };

  module TokenId = {
    public func equal(id1 : TokenId, id2 : TokenId) : Bool { id1 == id2 };
    public func hash(id : TokenId) : Hash.Hash { Word32.fromNat(Nat32.toNat(id)) };
  };
};