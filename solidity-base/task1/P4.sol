// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract P4 {
    function numberToRoman(uint number) public pure returns (string memory){
        require(number<3999,"number out of range");
        bytes memory charMap = bytes("IVXLCDM");// I=1 V=5, X=10 L=50, C=100 D=500, M=1000
        bytes memory result ;
        uint power = 4;  
        uint scale = 10000;
        while(scale > 0 && number > 0){
            power--; 
            scale /=10;
            if(scale > number){
                continue;
            }
            uint digit = number / scale;
            number = number % scale;
            if(digit == 9){
                result = abi.encodePacked(result, charMap[2*power]);
                result = abi.encodePacked(result, charMap[2*power+2]);
            }else if(digit == 4){
                result = abi.encodePacked(result, charMap[2*power]);
                result = abi.encodePacked(result, charMap[2*power+1]);
            }else {
                if(digit >= 5){
                    result = abi.encodePacked(result, charMap[2*power+1]);
                    digit -= 5;
                }
                for(uint i=0;i<digit;i++){
                    result = abi.encodePacked(result, charMap[2*power]);
                }
            }
        }
        return string(result);
    }

}