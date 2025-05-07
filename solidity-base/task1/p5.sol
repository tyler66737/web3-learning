// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract P5{
    function mergeSortedArray(uint[] memory a,uint[] memory b) public pure returns (uint[] memory) {
        uint[] memory c = new uint[](a.length + b.length);
        uint p1=0;
        uint p2=0;
        for(uint i=0;i<c.length;i++){
            if(p1<a.length && p2<b.length){
                if(a[p1]<b[p2]){
                    c[i] = a[p1];
                    p1++;
                }else{
                    c[i] = b[p2];
                    p2++;
                }
            }else if(p1<a.length){
                c[i] = a[p1];
                p1++;
            }else if(p2<b.length){
                c[i] = b[p2];
                p2++;
            }
        }
        return c;
    }
}
