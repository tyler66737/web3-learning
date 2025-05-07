// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract P3 { 
    function romanToNumber(string memory input) public pure returns (uint) {
        bytes memory bs = bytes(input);
        uint16 number = 0;
        bytes1 lastHalf = 0;
        for(uint256 i=bs.length;i>0;) {
            i--; // tricky
            bytes1 b = bs[i];
            if(b == 'I'){
                if(lastHalf == 'V' || lastHalf == 'X'){
                    number -= 1;
                }else{
                    number += 1 ;
                }
            }else if(b == 'V'){
                number += 5;
            }else if(b == 'X'){
                if(lastHalf == 'L' || lastHalf == 'C'){
                    number -= 10;
                }else{
                    number += 10 ;
                }
            }else if(b == 'L'){
                number += 50;
            }else if(b == 'C'){
                if(lastHalf == 'D' || lastHalf == 'M'){
                    number -= 100;
                }else{
                    number += 100 ;
                }
            }else if(b == 'D'){
                number += 500;
            }else if(b == 'M'){
                number += 1000;
            }else{
                revert("Invalid character");
            }
            lastHalf = b;
        }
        return number;
    }
}
