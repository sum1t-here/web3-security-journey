/*
* Verification of Sqrt
*/

methods {
    // function uniSqrt(uint256) external returns uint256 envfree;
    // function mathMasterSqrt(uint256) external returns uint256 envfree;
    function mathMasterTopHalf(uint256) external returns uint256 envfree;
    function solmateTopHalf(uint256) external returns uint256 envfree;
}

// rule check_testSqrt(uint256 x) {
//     assert(uniSqrt(x) == mathMasterSqrt(x));
// }

rule solmateTopHalfMatchesMathMasterTopHalf(uint256 x) {
    // find edge case and check using unit tests
    // if test passes add require(x != edge_case from certora)
    assert(solmateTopHalf(x) == mathMasterTopHalf(x));
}