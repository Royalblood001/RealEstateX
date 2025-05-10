
# 🏢 Real Estate Asset Administration Platform (v2)

A Clarity smart contract for decentralized and trust-enhanced management of real estate assets, enabling transparent property enrollment, tenant reservations, lifecycle monitoring, and payment handling.

---

## 📦 Features

* **Asset Enrollment**: Proprietors can register properties with configurable details like square footage, location, amenities, fees, and lease term.
* **Reservation & Tenancy Lifecycle**: Tenants reserve assets and finalize tenancy after meeting occupancy conditions.
* **Trust Scoring System**: Proprietors earn a trust score based on successful lease completions.
* **Capital Storage**: Secure funds management for both tenants and proprietors.
* **Withdrawals**: Proprietors can withdraw assets if unoccupied.
* **Validation Rules**: Strict input validations for occupancy durations, fees, space, and required fields.
* **Query Interfaces**: Access asset info, balances, owned properties, and proprietor ratings.
* **Asset Valuation**: Dynamically calculate asset market value based on size and fee ratio.

---

## 🧱 Data Structures

### Maps

* **`asset-catalog`**: Maps `asset-id` to asset details.
* **`capital-storage`**: Stores balances for each user.
* **`proprietor-trust-score`**: Tracks proprietor's reputation based on leasing success.
* **`proprietor-asset-portfolio`**: Tracks each proprietor's list (max 10) of enrolled assets.

### Variables

* **`inventory-counter`**: Tracks the total number of assets.

---

## 🚀 Core Functions

### 🔧 Public Functions

* **`enroll-asset`**: Register a new property.
* **`reserve-occupancy`**: Reserve an asset as a tenant.
* **`finalize-tenancy`**: Complete tenancy and transfer final payments.
* **`withdraw-asset`**: Withdraw an unoccupied asset.
* **`add-funds`**: Deposit capital to participate in the platform.

### 👓 Read-Only Functions

* **`fetch-asset-info`**: Get detailed information about an asset.
* **`view-account-balance`**: Check the balance of a user.
* **`check-proprietor-rating`**: Get the trust score of a proprietor.
* **`browse-owned-assets`**: View all assets owned by a proprietor.
* **`calculate-asset-value`**: Compute asset value including proprietor fee.

---

## ⚠️ Error Codes

| Code   | Description                         |
| ------ | ----------------------------------- |
| `u401` | Authorization error                 |
| `u402` | Asset already has an occupant       |
| `u403` | Insufficient balance                |
| `u404` | Asset not found or unavailable      |
| `u405` | Waiting period for tenancy not met  |
| `u406` | Invalid square footage              |
| `u407` | Fee exceeds allowable limit         |
| `u408` | Invalid occupancy duration          |
| `u409` | Asset ID does not exist             |
| `u411` | Inactive asset                      |
| `u412` | Minimum deposit requirement not met |
| `u413` | Location details required           |
| `u414` | Amenity details required            |

---

## 💡 Usage Flow

1. **Proprietor**:

   * Calls `add-funds` to deposit initial capital.
   * Calls `enroll-asset` to list a new property.

2. **Tenant**:

   * Calls `add-funds` to load balance.
   * Calls `reserve-occupancy` to reserve an asset.
   * Waits for the specified term.
   * Calls `finalize-tenancy` to complete the lease and trigger payments.

3. **Proprietor** (Optional):

   * May call `withdraw-asset` to remove a listing if it's still open.

---

## 📐 Asset Value Formula

```
asset-value = square-footage + (square-footage * proprietor-fee / 100)
```

---

## 🛠️ Developer Notes

* Max 10 assets tracked per proprietor in their portfolio.
* All strings are ASCII-bounded for efficient on-chain storage.
* The system handles payment transfers internally within the `capital-storage` map.
* The contract is upgrade-ready with modular validation and storage logic.
