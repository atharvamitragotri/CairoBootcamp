%lang starknet

from starkware.cairo.common.uint256 import Uint256, uint256_sub, uint256_eq
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin

const MINT_ADMIN = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04a91;
const TEST_ACC1 = 0x00348f5537be66815eb7de63295fcb5d8b8b2ffe09bb712af4966db7cbb04a95;
const TEST_ACC2 = 0x3fe90a1958bb8468fb1b62970747d8a00c435ef96cda708ae8de3d07f1bb56b;

from exercises.contracts.erc20.IERC20 import IErc20 as Erc20

@external
func __setup__() {
    // Deploy contract
    %{
        context.contract_a_address  = deploy_contract("./exercises/contracts/erc20/shamecoin.cairo", [
               5338434412023108646027945078640, ## name:   CairoWorkshop
               17239,                           ## symbol: CW
               0,                               ## decimals: 0
               10000000000,                     ## initial_supply[1]: 10000000000
               0,                               ## initial_supply[0]: 0
               ids.MINT_ADMIN
               ]).contract_address
    %}
    return ();
}

@external
func test_transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    tempvar contract_address;
    %{ ids.contract_address = context.contract_a_address %}
    %{print(ids.contract_address)%}

    // Call as admin
    %{ stop_prank_callable = start_prank(ids.MINT_ADMIN, ids.contract_address) %}

    // Transfer 1 shame coin as mint owner to TEST_ACC1
    Erc20.transfer(contract_address=contract_address, recipient=TEST_ACC1, amount=Uint256(1, 0));
    let (user_balance) = Erc20.balanceOf(
        contract_address=contract_address, account=TEST_ACC1
    );

    // Attempt to transfer >1 shamecoin as mint owner to TEST_ACC1
    %{ expect_revert() %}
    Erc20.transfer(contract_address=contract_address, recipient=TEST_ACC2, amount=Uint256(111, 0));
    
    // Stop and call using Test Acc 2
    %{ stop_prank_callable() %}
    %{ stop_prank_callable = start_prank(ids.TEST_ACC2, ids.contract_address) %}
    
    // Transfer 1 shame coin as TEST_ACC2 to TEST_ACC1
    Erc20.transfer(contract_address=contract_address, recipient=TEST_ACC1, amount=Uint256(1, 0));
    let (user2_balance) = Erc20.balanceOf(
        contract_address=contract_address, account=TEST_ACC2
    );

    // Check if test acc 1 balance is equal to one
    let (user_balance_is_one) = uint256_eq(user_balance, Uint256(1,0));
    assert user_balance_is_one = TRUE;   

    // Check if test acc 2 balance is equal to one
    let (user2_balance_is_one) = uint256_eq(user2_balance, Uint256(1,0));
    assert user2_balance_is_one = TRUE;

    %{ stop_prank_callable() %}

    return ();
}

@external
func test_approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    tempvar contract_address;
    %{ ids.contract_address = context.contract_a_address %}

    // Call as admin
    %{ stop_prank_callable = start_prank(ids.MINT_ADMIN, ids.contract_address) %}
    // Try to approve as admin
     %{ expect_revert() %}
    Erc20.approve(contract_address=contract_address, spender=TEST_ACC1, amount=Uint256(1, 0));
    %{ stop_prank_callable() %}

    // Call as test_acc2
    %{ stop_prank_callable = start_prank(ids.TEST_ACC2, ids.contract_address) %}
    
    // Initialize TEST_ACC2 balance
    Erc20.transfer(contract_address=contract_address, recipient=TEST_ACC1, amount=Uint256(1, 0));
    
    // Try to approve for admin to spend
    Erc20.approve(contract_address=contract_address, spender=MINT_ADMIN, amount=Uint256(1, 0));
    let (spender_allowance) = Erc20.allowance(contract_address=contract_address, owner=TEST_ACC2, spender=MINT_ADMIN);
    assert spender_allowance = Uint256(1, 0);
    
    %{ stop_prank_callable() %}
    return ();
}

@external
func test_transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    tempvar contract_address;
    %{ ids.contract_address = context.contract_a_address %}

    // Call as test_acc1
    %{ stop_prank_callable = start_prank(ids.TEST_ACC1, ids.contract_address) %}
    // Initialize TEST_ACC1 balance
    Erc20.transfer(contract_address=contract_address, recipient=TEST_ACC2, amount=Uint256(1, 0));


    // Start user balance
    let (start_user_balance) = Erc20.balanceOf(
        contract_address=contract_address, account=TEST_ACC1
    );
    %{print("start_user_balance: ",ids.start_user_balance.low)%}

    // Call transferrFrom
    Erc20.transferFrom(
        contract_address=contract_address,
        sender=TEST_ACC1,
        recipient=TEST_ACC2,
        amount=Uint256(1, 0)
    );
    let (new_user_balance) = Erc20.balanceOf(
        contract_address=contract_address, account=TEST_ACC1
    );
    assert new_user_balance = Uint256(0,0);
    %{ stop_prank_callable() %}

    return ();
}
