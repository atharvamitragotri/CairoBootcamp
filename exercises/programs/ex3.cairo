// Perform and log output of simple arithmetic operations
from starkware.cairo.common.math import unsigned_div_rem
func simple_math{range_check_ptr}() {
   // adding 13 +  14
    let sum=13+14;
    %{print(ids.sum)%}
   // multiplying 3 * 6
    let product=3*6;
    %{print(ids.product)%}
   // dividing 6 by 2
    let quo=6/2;
    %{print(ids.quo)%}
   // dividing 70 by 2
    let quo2=70/2;
    %{print(ids.quo2)%}
   // dividing 7 by 2
    let (quo3, _) = unsigned_div_rem(7, 2);
    %{print(ids.quo3)%}
    return ();
}
