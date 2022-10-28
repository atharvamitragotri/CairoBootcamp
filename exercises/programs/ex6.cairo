from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem

// Implement a function that sums even numbers from the provided array
func sum_even{bitwise_ptr: BitwiseBuiltin*,range_check_ptr}(arr_len: felt, arr: felt*, run: felt, idx: felt) -> (
    sum: felt
) {
    if (arr_len == 0) {
        return (sum = 0);
    }
    let (sum) = sum_even(arr_len=arr_len-1,arr=arr+1,run=run,idx=idx);
    let (oddOrEven) = bitwise_and(arr[0],1);
    if (oddOrEven==1){
        return (sum=sum);
    }
    let sum_of_even = sum + arr[0];
    return (sum = sum_of_even);
}
