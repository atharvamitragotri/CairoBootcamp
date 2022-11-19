%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math import unsigned_div_rem, assert_le_felt, assert_le, assert_nn, assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.pow import pow
from starkware.cairo.common.hash_state import hash_init, hash_update
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor, bitwise_or
from lib.constants import TRUE, FALSE

// Structs
//#########################################################################################

struct Consortium {
    chairperson: felt,
    proposal_count: felt,
}

struct Member {
    votes: felt,
    prop: felt,
    ans: felt,
}

struct Answer {
    text: felt,
    votes: felt,
}

struct Proposal {
    type: felt,  // whether new answers can be added
    win_idx: felt,  // index of preffered option
    ans_idx: felt,
    deadline: felt,
    over: felt,
}

// remove in the final asnwerless
struct Winner {
    highest: felt,
    idx: felt,
}

// Storage
//#########################################################################################

@storage_var
func consortium_idx() -> (idx: felt) {
}

@storage_var
func consortiums(consortium_idx: felt) -> (consortium: Consortium) {
}

@storage_var
func members(consortium_idx: felt, member_addr: felt) -> (memb: Member) {
}

@storage_var
func proposals(consortium_idx: felt, proposal_idx: felt) -> (win_idx: Proposal) {
}

@storage_var
func proposals_idx(consortium_idx: felt) -> (idx: felt) {
}

@storage_var
func proposals_title(consortium_idx: felt, proposal_idx: felt, string_idx: felt) -> (
    substring: felt
) {
}

@storage_var
func proposals_link(consortium_idx: felt, proposal_idx: felt, string_idx: felt) -> (
    substring: felt
) {
}

@storage_var
func proposals_answers(consortium_idx: felt, proposal_idx: felt, answer_idx: felt) -> (
    answers: Answer
) {
}

@storage_var
func voted(consortium_idx: felt, proposal_idx: felt, member_addr: felt) -> (true: felt) {
}

@storage_var
func answered(consortium_idx: felt, proposal_idx: felt, member_addr: felt) -> (true: felt) {
}

// External functions
//#########################################################################################

@external
func create_consortium{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    // Create consortium
    let (caller) = get_caller_address();
    let new_consortium = Consortium(chairperson=caller,proposal_count=0);
    // Add consortium
    let (new_con_idx) = consortium_idx.read();
    consortiums.write(new_con_idx, new_consortium);
    // Add chairperson as member
    let new_member = Member(votes=100,prop=TRUE,ans=TRUE);
    members.write(new_con_idx, caller, new_member);
    // Increase counter
    let (con_idx) = consortium_idx.read();
    consortium_idx.write(con_idx+1);
    return ();
}

@external
func add_proposal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt,
    title_len: felt,
    title: felt*,
    link_len: felt,
    link: felt*,
    ans_len: felt,
    ans: felt*,
    type: felt,
    deadline: felt,
) {
    alloc_locals;

    let (caller) = get_caller_address();
    let (can_prop) = members.read(consortium_idx, caller);
    assert can_prop.prop = TRUE; 

    let (prop_idx) = proposals_idx.read(consortium_idx);

    // proposal title
    if (title_len == 1){
        proposals_title.write(consortium_idx, prop_idx, 0, [title]);      
    } else{
        load_selector(title_len, title, 0, prop_idx, consortium_idx, 0, 0);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    // proposal link
    if (link_len == 1){
        proposals_link.write(consortium_idx, prop_idx, [link], 0);
    } else{
        load_selector(link_len, link, 0, prop_idx, consortium_idx, 1, 0);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    // add answers
    load_selector(ans_len, ans, 0, prop_idx, consortium_idx, 2, 0);

    // add proposal
    let new_proposal = Proposal(type=type,win_idx=0,ans_idx=ans_len-1,deadline=deadline,0);
    proposals.write(consortium_idx, prop_idx, new_proposal);

    // set proposal count
    let new_prop_idx = prop_idx + 1;
    proposals_idx.write(consortium_idx,new_prop_idx);
    return ();
}

@external
func add_member{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, member_addr: felt, prop: felt, ans: felt, votes: felt
) {
    alloc_locals;

    let (caller) = get_caller_address();
    let (consortium) = consortiums.read(consortium_idx);
    assert caller = consortium.chairperson;

    // add member
    let new_member = Member(votes=votes,prop=prop,ans=ans);
    members.write(consortium_idx, member_addr, new_member);
    return ();
}

@external
func add_answer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, proposal_idx: felt, string_len: felt, string: felt*
) {
    alloc_locals;

    let (caller) = get_caller_address();
    let (can_ans) = members.read(consortium_idx, caller);
    assert can_ans.ans = TRUE; 

    // add answer            
    let (proposal) = proposals.read(consortium_idx, proposal_idx);
    tempvar anss = proposal.ans_idx;
    %{ print(f"Answer idx : {ids.anss}") %}
    let new_ans_idx = proposal.ans_idx + 1;
    proposals_answers.write(consortium_idx, proposal_idx, new_ans_idx, Answer([string],0));

    proposals.write(consortium_idx, proposal_idx, Proposal(proposal.type, proposal.win_idx, proposal.ans_idx + 1, proposal.deadline, proposal.over));
    answered.write(consortium_idx, proposal_idx, caller, TRUE);
    return ();
}

@external
func vote_answer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, proposal_idx: felt, answer_idx: felt
) {
    alloc_locals;

    // check if member has at least 1 vote
    let (caller) = get_caller_address();
    let (member) = members.read(consortium_idx, caller);
    assert_not_zero(member.votes) ;

    // check if caller has voted on current proposal
    let (hasVoted) = voted.read(consortium_idx, proposal_idx, caller);
    assert hasVoted = 0;

    // cast vote
    let (answer) = proposals_answers.read(consortium_idx, proposal_idx, answer_idx);
    let existingVotes = answer.votes;
    let updated_answer = Answer(answer.text, existingVotes + member.votes);
    proposals_answers.write(consortium_idx, proposal_idx, answer_idx, updated_answer);

    // mark caller as voted
    voted.write(consortium_idx, proposal_idx, caller, 1);

    return ();
}

@external
func tally{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, proposal_idx: felt
) -> (win_idx: felt) {
    let (caller) = get_caller_address();
    let (consortium) = consortiums.read(consortium_idx);
    assert caller = consortium.chairperson;

    let (proposal) = proposals.read(consortium_idx, proposal_idx);
    let last_ans_idx = proposal.ans_idx;

    let (winner_idx) = find_highest(consortium_idx, proposal_idx, 0, 0, last_ans_idx);

    return (win_idx=winner_idx);

}


// Internal functions
//#########################################################################################


func find_highest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    consortium_idx: felt, proposal_idx: felt, highest: felt, idx: felt, countdown: felt
) -> (idx: felt) {
    alloc_locals;
    if (countdown == 0){
        return (idx,);
    }
    let (answer) = proposals_answers.read(consortium_idx, proposal_idx, idx);
    let is_highest = is_le(highest, answer.votes);
    if (is_highest == 1){
        let (res) = find_highest(consortium_idx, proposal_idx, answer.votes, idx + 1, countdown - 1);
        return (res,);
    }
    let (idx) = find_highest(consortium_idx, proposal_idx, highest, idx + 1, countdown - 1);
    return (idx,);    
}

// Loads it based on length, internall calls only
// selector : 0 - Proposal title, 1 - Proposal link, 2 - Proposal answers
func load_selector{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    string_len: felt,
    string: felt*,
    slot_idx: felt,
    proposal_idx: felt,
    consortium_idx: felt,
    selector: felt,
    offset: felt,
) {
    // alloc_locals;

    // for answers
    if (selector == 2){
        if (string_len == 0){
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else{
            proposals_answers.write(consortium_idx, proposal_idx, string_len - 1, Answer(string[string_len - 1],0));
            load_selector(string_len - 1, string, slot_idx, proposal_idx, consortium_idx, selector, offset);
            
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        // for link
        if (selector == 1){
            if (string_len == 0){
                tempvar syscall_ptr = syscall_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
                tempvar range_check_ptr = range_check_ptr;
            } else {
                proposals_link.write(consortium_idx, proposal_idx, string_len - 1, string[string_len - 1]);
                load_selector(string_len - 1, string, slot_idx, proposal_idx, consortium_idx, selector, offset);
                tempvar syscall_ptr = syscall_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
                tempvar range_check_ptr = range_check_ptr;
            }
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            // for title
            if (selector == 0){
                if (string_len == 0){
                    tempvar syscall_ptr = syscall_ptr;
                    tempvar pedersen_ptr = pedersen_ptr;
                    tempvar range_check_ptr = range_check_ptr;
                } else {
                    proposals_title.write(consortium_idx, proposal_idx, string_len - 1, string[string_len - 1]);
                    load_selector(string_len - 1, string, slot_idx, proposal_idx, consortium_idx, selector, offset);
                    tempvar syscall_ptr = syscall_ptr;
                    tempvar pedersen_ptr = pedersen_ptr;
                    tempvar range_check_ptr = range_check_ptr;
                }
            } else{
                tempvar syscall_ptr = syscall_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
                tempvar range_check_ptr = range_check_ptr;
            }
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }
    
    return ();
}