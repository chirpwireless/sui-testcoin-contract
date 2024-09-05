# Testcoin Token

Testcoin contract for testing purposes.

## Deploying contract

```sh
sui client publish --gas-budget 1000000000
```

## Running tests

```sh
sui move test --gas-limit 1000000000
```

## Minting coins

Replace `$PACKAGE_ID` with your contract's package ID and `$VAULT_ID` with the ID of the shared vault.

```sh
sui client call --package $PACKAGE_ID --module testcoin --function mint --args $VAULT_ID 0x6
```

## Deposit coins to the depository

Replace `$PACKAGE_ID` with your contract's package ID, `$VAULT_ID` with the shared vault ID, `$RECIPIENT` with the recipient's wallet address, and `$COIN_ID` with the coin's ID to deposit.

```sh
sui client call --package $PACKAGE_ID --module testcoin --function deposit --args $VAULT_ID '[$RECIPIENT]' '[$COIN_ID]'
```

## Claim coins from the depository

Replace `$PACKAGE_ID` with your contract's package ID, `$VAULT_ID` with the shared vault ID, and `$AMOUNT` with the number of coins to claim.

```sh
sui client call --package $PACKAGE_ID --module testcoin --function claim --args $VAULT_ID $AMOUNT
```
