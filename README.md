# Stacksy NFT Marketplace

Stacksy is a decentralized NFT marketplace built on the Stacks blockchain that supports SIP-009 compliant NFTs with royalties.

## Features

- List SIP-009 NFTs for sale
- Buy listed NFTs
- Cancel existing listings
- Royalty support for NFT creators/collections
- Owner-controlled royalty rate setting

## Contract Functions

### For NFT Sellers

```clarity
(list-token (nft-contract <nft-trait>) (token-id uint) (price uint))
```
List an NFT for sale at a specified price. The NFT will be held in escrow by the contract.

```clarity
(cancel-listing (nft-contract <nft-trait>) (token-id uint))
```
Cancel an existing listing and return the NFT to the seller.

### For NFT Buyers

```clarity
(buy-nft-token (nft-contract <nft-trait>) (token-id uint))
```
Purchase a listed NFT. The price will be transferred to the seller and any applicable royalties will be paid.

### For Contract Owner

```clarity
(set-royalty (nft <nft-trait>) (rate uint))
```
Set the royalty rate for a specific NFT contract (0-100%).

