// contract creation code
// 0x6080604052348015600e575f5ffd5b506101298061001c5f395ff3

// runtime
// fe6080604052348015600e575f5ffd5b50600436106030575f3560e01c8063cdfead2e146034578063e026c01714604c575b5f5ffd5b604a60048036038101906046919060a9565b6066565b005b6052606f565b604051605d919060dc565b60405180910390f35b805f8190555050565b5f5f54905090565b5f5ffd5b5f819050919050565b608b81607b565b81146094575f5ffd5b50565b5f8135905060a3816084565b92915050565b5f6020828403121560bb5760ba6077565b5b5f60c6848285016097565b91505092915050565b60d681607b565b82525050565b5f60208201905060ed5f83018460cf565b9291505056

// metadata
// fea264697066735822122067e470313f98f7a105e9998854a5e960a7da39f3f1d526fdb187cdc3f969d49664736f6c63430008220033

// 3 sections
// 1. Contract Creation Code
// 2. Runtime
// 3. Metadata

// 1. Contract Creation Code
// Free memory pointer (0x40 -> this index in memory tells the compiler which memory to use)
PUSH1 0x80                      // [0x80]
PUSH1 0x40                      // [0x40, 0x80]
MSTORE                          // []      // Memory 0x40 -> 0x80

// If someone sends value with this call revert else jump to 0x0e PC/Jumpdest
CALLVALUE                       // [msg.value]
DUP1                            // [msg.value, msg.value]
ISZERO                          // [msg.value == 0, msg.value]
PUSH1 0x0e                      // [0x0e, msg.value == 0, msg.value]
JUMPI                           // [msg.value]
PUSH0                           // [0x00, msg.value]
PUSH0                           // [0x00, 0x00, msg.value]
REVERT                          // [msg.value]

// Jumpdest if msg.value == 0
// sticks runtime code on chain
JUMPDEST                        // [msg.value]
POP                             // []
PUSH2 0x0129                    // [0x0129]
DUP1                            // [0x0129, 0x0129]
PUSH2 0x001c                    // [0x001c, 0x0129, 0x0129]
PUSH0                           // [0x00, 0x001c, 0x0129, 0x0129]
CODECOPY                        // [0x0129]              Memory: [runtime code]
PUSH0                           // [0x00, 0x0129]
RETURN                          // []
INVALID                         // []


// 2. Runtime code
// Entry point of all calls
// free memory pointer
PUSH1 0x80                      // [0x80]
PUSH1 0x40                      // [0x40, 0x80]
MSTORE                          // []       Memory 0x40 -> 0x80

// If someone sends value with this call revert else jump to 0x0e PC/Jumpdest
CALLVALUE                       // [msg.value]
DUP1                            // [msg.value, msg.value]
ISZERO                          // [msg.value == 0, msg.value]
PUSH1 0x0e                      // [0x0e, msg.value == 0, msg.value]
JUMPI                           // [msg.value]
PUSH0                           // [0x00, msg.value]
PUSH0                           // [0x00, 0x00, msg.value]
REVERT                          // [msg.value]

// Jumpdest if msg.value == 0
// this is checking to see if there is enough calldata for function selector
JUMPDEST                        // [msg.value]
POP                             // []
PUSH1 0x04                      // [0x04]
CALLDATASIZE                    // [calldata_size, 0x04]
LT                              // [calldata_size < 0x04]
PUSH1 0x30                      // [0x30, calldata_size < 0x04]
JUMPI                           // []
// Jumpdest if calldata_size < 0x04

PUSH0                           // [0x00]
CALLDATALOAD                    // [32 bytes of calldata]
PUSH1 0xe0                      // [0xe0, 32 bytes of calldata]
SHR                             // [calldata[0:4]] -> function selector
DUP1                            // [calldata[0:4], calldata[0:4]]
PUSH4 0xcdfead2e                // [0xcdfead2e, calldata[0:4], calldata[0:4]]
EQ                              // [calldata[0:4] == 0xcdfead2e, calldata[0:4]]
PUSH1 0x34                      // [0x34, calldata[0:4] == 0xcdfead2e, calldata[0:4]]
JUMPI                           // [calldata[0:4]]
// Jumpdest if calldata[0:4] == 0xcdfead2e

DUP1                            // [calldata[0:4], calldata[0:4]]
PUSH4 0xe026c017                // [0xe026c017, calldata[0:4], calldata[0:4]]
EQ                              // [calldata[0:4] == 0xe026c017, calldata[0:4]]
PUSH1 0x4c                      // [0x4c, calldata[0:4] == 0xe026c017, calldata[0:4]]
JUMPI                           // [calldata[0:4]]
// Jumpdest if calldata[0:4] == 0xe026c017

// Jumpdest if calldata_size < 0x04
// revert
JUMPDEST                        // []
PUSH0                           // [0x00]
PUSH0                           // [0x00, 0x00]
REVERT                          // []

// updateHorseNumber
JUMPDEST                        // [calldata[0:4]]
PUSH1 0x4a                      // [0x4a, calldata[0:4]]
PUSH1 0x04                      // [0x04, 0x4a, calldata[0:4]]
DUP1                            // [calldata[0:4], 0x04, 0x4a, calldata[0:4]]
CALLDATASIZE                    // [calldata_size, calldata[0:4], 0x04, 0x4a, calldata[0:4]]
SUB                             // [calldata_size - 0x04, calldata[0:4], 0x4a, calldata[0:4]]
DUP2                            // [calldata[0:4], calldata_size - 0x04, calldata[0:4], 0x4a, calldata[0:4]]
ADD                             // [calldata_size, calldata[0:4], 0x4a, calldata[0:4]]
SWAP1                           // [calldata[0:4], calldata_size, 0x4a, calldata[0:4]]
PUSH1 0x46                      // [0x46, calldata[0:4], calldata_size, 0x4a, calldata[0:4]]
SWAP2                           // [calldata_size, 0x46, calldata[0:4], 0x4a, calldata[0:4]]
SWAP1                           // [0x46, calldata_size, calldata[0:4], 0x4a, calldata[0:4]]
PUSH1 0xa9                      // [0xa9, 0x46, calldata_size, calldata[0:4], 0x4a, calldata[0:4]]
JUMP                            // [calldata_size, calldata[0:4], 0x4a, calldata[0:4]]

JUMPDEST
PUSH1 0x66
JUMP

JUMPDEST
STOP

JUMPDEST
PUSH1 0x52
PUSH1 0x6f
JUMP

JUMPDEST
PUSH1 0x40
MLOAD
PUSH1 0x5d
SWAP2
SWAP1
PUSH1 0xdc
JUMP

JUMPDEST
PUSH1 0x40
MLOAD
DUP1
SWAP2
SUB
SWAP1
RETURN

JUMPDEST
DUP1
PUSH0
DUP2
SWAP1
SSTORE
POP
POP
JUMP

JUMPDEST
PUSH0
PUSH0
SLOAD
SWAP1
POP
SWAP1
JUMP

JUMPDEST
PUSH0
PUSH0
REVERT

JUMPDEST
PUSH0
DUP2
SWAP1
POP
SWAP2
SWAP1
POP
JUMP

JUMPDEST
PUSH1 0x8b
DUP2
PUSH1 0x7b
JUMP

JUMPDEST
DUP2
EQ
PUSH1 0x94
JUMPI

PUSH0
PUSH0
REVERT

JUMPDEST
POP
JUMP

JUMPDEST
PUSH0
DUP2
CALLDATALOAD
SWAP1
POP
PUSH1 0xa3
DUP2
PUSH1 0x84
JUMP

JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP

JUMPDEST
PUSH0
PUSH1 0x20
DUP3
DUP5
SUB
SLT
ISZERO
PUSH1 0xbb
JUMPI

PUSH1 0xba
PUSH1 0x77
JUMP

JUMPDEST

JUMPDEST
PUSH0
PUSH1 0xc6
DUP5
DUP3
DUP6
ADD
PUSH1 0x97
JUMP

JUMPDEST
SWAP2
POP
POP
SWAP3
SWAP2
POP
POP
JUMP

JUMPDEST
PUSH1 0xd6
DUP2
PUSH1 0x7b
JUMP

JUMPDEST
DUP3
MSTORE
POP
POP
JUMP

JUMPDEST
PUSH0
PUSH1 0x20
DUP3
ADD
SWAP1
POP
PUSH1 0xed
PUSH0
DUP4
ADD
DUP5
PUSH1 0xcf
JUMP

JUMPDEST
SWAP3
SWAP2
POP
POP
JUMP

// 3. Metadata
INVALID
LOG2
PUSH5 0x6970667358
INVALID
SLT
KECCAK256
PUSH8 0xe470313f98f7a105
INVALID
SWAP10
DUP9
SLOAD
INVALID
INVALID
PUSH1 0xa7
INVALID
CODECOPY
RETURN
CALL
INVALID
INVALID
REVERT
INVALID
DUP8
INVALID
INVALID
INVALID
PUSH10 0xd49664736f6c63430008
INVALID
STOP
CALLER