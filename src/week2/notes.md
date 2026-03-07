## Target for this week

- fallback
- delegatecall
- tx.origin

#### Fallback
Two ways to trigger fallback:
- Send ETH with some random calldata that doesn't match any function
- Call a function that doesn't exist on the contract

#### Delegatecall
- delegatecall executes another contract's code but modifies the caller's own storage.

#### tx.origin
If contract A calls B, and B calls C, in C `msg.sender` is B and `tx.origin` is A