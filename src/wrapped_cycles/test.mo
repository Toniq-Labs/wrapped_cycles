import Cycles "mo:base/ExperimentalCycles";
actor {
  public func accept() : async () {
    let available = Cycles.available();
    let accepted = Cycles.accept(available);
    assert (accepted == available);
  };
  public query func availableCycles() : async Nat {
    return Cycles.balance()
  };
}