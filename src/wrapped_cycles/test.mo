import Cycles "mo:base/ExperimentalCycles";
actor {
  public func accept_cycles() : async () {
    Cycles.accept(Cycles.available());
  };
  public query func availableCycles() : async Nat {
    return Cycles.balance()
  };
}