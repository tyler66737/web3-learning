// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract P2 { 
    function reverseString(string memory s) public pure returns (string memory) {
        bytes memory bs = bytes(s);
        uint lo = 0;
        uint hi = bs.length-1;
        while (lo < hi) {
            (bs[lo], bs[hi]) = (bs[hi], bs[lo]);
            lo++;
            hi--;
        }
        return string(bs);
    }
}
