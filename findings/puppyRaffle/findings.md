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
+ mapping(address => bool) public playerEntered;

  function enterRaffle(address[] memory newPlayers) public payable {
      require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
+     
+     // Check for duplicates using O(1) mapping lookup
+     for (uint256 i = 0; i < newPlayers.length; i++) {
+         require(!playerEntered[newPlayers[i]], "PuppyRaffle: Duplicate player");
+         playerEntered[newPlayers[i]] = true;
+         players.push(newPlayers[i]);
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
```