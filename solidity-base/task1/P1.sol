// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract Voting { 
    mapping(uint => uint) private votes;
    uint private candidates;

    constructor(uint _candidate) {
        require(_candidate > 0, "Candidate must be greater than 0.");
        candidates = _candidate;
    }

    function vote(uint candidateID) public {
        votes[candidateID]++;
    }

    function getVotes(uint candidateID) public view returns (uint) {
        return votes[candidateID];
    }

    function resetVotes() external {
        for(uint i = 0; i < candidates; i++){
            votes[i] = 0;
        }
    }
}
