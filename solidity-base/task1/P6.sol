// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract P6{
    function binarySearch(uint[] memory nums,uint target) public pure returns (int) {
       int lo = 0; 
       int hi = int(nums.length) - 1;
       while(lo<=hi){
           int mid = (lo + hi) / 2;
           if(nums[uint(mid)] == target){
                return mid;
           }else if(nums[uint(mid)] < target){
               lo = mid + 1;
           }else{
               hi = mid - 1;
           }
       }
       return -1;
    }
}
