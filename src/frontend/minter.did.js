export default ({ IDL }) => {
  const SubAccount = IDL.Vec(IDL.Nat8);
  const Memo = IDL.Nat64;
  const ICPTs = IDL.Record({ 'e8s' : IDL.Nat64 });
  const BlockHeight = IDL.Nat64;
  const TransactionNotification = IDL.Record({
    'to' : IDL.Principal,
    'to_subaccount' : IDL.Opt(SubAccount),
    'from' : IDL.Principal,
    'memo' : Memo,
    'from_subaccount' : IDL.Opt(SubAccount),
    'amount' : ICPTs,
    'block_height' : BlockHeight,
  });
  const Result = IDL.Variant({ 'Ok' : IDL.Null, 'Err' : IDL.Text });
  return IDL.Service({
    'acceptCycles' : IDL.Func([], [], []),
    'availableCycles' : IDL.Func([], [IDL.Nat], ['query']),
    'getErrors' : IDL.Func([], [IDL.Vec(IDL.Text)], ['query']),
    'getTns' : IDL.Func([], [IDL.Vec(TransactionNotification)], ['query']),
    'transaction_notification' : IDL.Func(
        [TransactionNotification],
        [Result],
        [],
      ),
  });
};
export const init = ({ IDL }) => { return []; };