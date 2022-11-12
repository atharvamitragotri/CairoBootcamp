// Task:
// Develop logic of set balance and get balance methods
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.access.ownable import Ownable
from starkware.starknet.common.syscalls import get_caller_address

@constructor
func constructor{syscall_ptr:felt*, pedersen_ptr:HashBuiltin*, range_check_ptr}(owner:felt){
    Ownable.initializer(owner);
    return ();
}

@external
func get_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    return Ownable.owner();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(new_owner: felt){
    Ownable.transfer_ownership(new_owner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(){
    Ownable.renounce_ownership();
    return ();
}

@external
func checkOwnable{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (isOwner:felt){
    Ownable.assert_only_owner();
    return (isOwner=1);
}

// Define a storage variable.
@storage_var
func balance() -> (res: felt) {
}

// Returns the current balance.
@view
func get_balance{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}() -> (res: felt) {
    let (bal)=balance.read();
    return (res=bal);
}

// Sets the balance to amount
@external
func set_balance{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
}(amount: felt) {
    let (isOwner) = checkOwnable();
    assert isOwner = 1;
    balance.write(amount);
    return ();
}