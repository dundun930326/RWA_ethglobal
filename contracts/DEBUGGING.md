# mintWithSignature 錯誤診斷指南

當你看到 "revert" 錯誤但沒有具體訊息時，可能是以下原因之一：

## 🔍 檢查清單

### 1. 用戶是否在白名單中？
```solidity
// 檢查方法
bool isWhitelisted = factory.whitelist(userAddress);

// 如果返回 false，需要先添加到白名單
factory.addToWhitelist(userAddress, "ipfs://your-metadata-uri");
```
**錯誤訊息**：`"Not whitelisted"`

---

### 2. 用戶是否有預先分配的 URI？
```solidity
// 檢查方法
string memory uri = factory.whitelistURIs(userAddress);

// 如果 uri 為空字符串，需要重新添加到白名單並指定 URI
factory.addToWhitelist(userAddress, "ipfs://your-metadata-uri");
```
**錯誤訊息**：`"No URI assigned for this address"`

---

### 3. 用戶是否已經從這個 RWA 合約 mint 過？
```solidity
// 檢查方法
bool alreadyMinted = factory.hasMinted(rwaAddress, userAddress);

// 如果返回 true，表示用戶已經 mint 過，不能再次 mint
// 每個用戶每個 RWA 合約只能 mint 一次
```
**錯誤訊息**：`"Already minted from this RWA"`

---

### 4. RWA 合約的 owner 是否為 Factory？⚠️ **最常見的問題**
```solidity
// 檢查方法
address rwaOwner = RWA(rwaAddress).owner();
address factoryAddress = address(factory);

// rwaOwner 必須等於 factoryAddress
// 如果不相等，Factory 無法調用 RWA.safeMint()
```
**錯誤訊息**：`OwnableUnauthorizedAccount`

#### 解決方案：
- **方案 A（推薦）**：使用 Factory 的 `createRWA()` 函數部署新的 RWA
  ```solidity
  address newRWA = factory.createRWA();
  ```
  
- **方案 B**：如果 RWA 已存在，將其所有權轉移給 Factory
  ```solidity
  // 需要作為 RWA 的當前 owner 執行
  rwa.transferOwnership(address(factory));
  ```

---

## 🛠️ 使用診斷腳本

我創建了一個診斷腳本來幫助你檢查所有條件：

```bash
# 在 Remix 或本地環境運行
forge script script/DebugMint.s.sol:DebugMint --rpc-url <YOUR_RPC_URL>
```

記得在腳本中替換你的實際地址！

---

## 📝 正確的使用流程

### 步驟 1：部署 Factory（僅一次）
```solidity
RWAFactory factory = new RWAFactory();
// Factory 在構造函數中會自動部署第一個 RWA
```

### 步驟 2：添加用戶到白名單
```solidity
factory.addToWhitelist(
    userAddress, 
    "ipfs://QmX...abc123"  // 用戶的 NFT 元數據 URI
);
```

### 步驟 3：（可選）部署更多 RWA 合約
```solidity
address newRWA = factory.createRWA();
```

### 步驟 4：用戶 mint NFT
```solidity
// 獲取可用的 RWA 地址
address[] memory deployedRWAs = factory.getDeployedRWAs();
address rwaAddress = deployedRWAs[0];

// Mint
uint256 tokenId = factory.mintWithSignature(
    rwaAddress,
    ""  // signature 目前未使用
);
```

---

## 🔧 在 Remix 中調試

1. **部署合約後，立即檢查**：
   ```solidity
   // 檢查 Factory 地址
   address factoryAddr = address(factory);
   
   // 檢查第一個 RWA
   address rwa1 = factory.deployedRWAs(0);
   
   // 檢查 RWA 的 owner
   address owner = RWA(rwa1).owner();
   
   // 確認 owner == factoryAddr
   ```

2. **添加用戶到白名單前**：
   ```solidity
   // 檢查用戶是否已在白名單
   bool isWhitelisted = factory.whitelist(YOUR_ADDRESS);
   ```

3. **Mint 前**：
   ```solidity
   // 檢查是否已經 mint 過
   bool hasMinted = factory.hasMinted(rwaAddress, YOUR_ADDRESS);
   ```

---

## ⚠️ 常見錯誤

### 錯誤 1：手動部署的 RWA
```solidity
// ❌ 錯誤做法
RWA rwa = new RWA();
factory.mintWithSignature(address(rwa), ""); // 會失敗！

// ✅ 正確做法
address rwa = factory.createRWA(); // 讓 Factory 部署
factory.mintWithSignature(rwa, "");
```

### 錯誤 2：忘記添加到白名單
```solidity
// ❌ 錯誤做法
factory.mintWithSignature(rwaAddress, ""); // 會失敗！

// ✅ 正確做法
factory.addToWhitelist(msg.sender, "ipfs://...");
factory.mintWithSignature(rwaAddress, "");
```

### 錯誤 3：使用錯誤的地址
```solidity
// ❌ 錯誤做法 - 使用隨機地址
factory.mintWithSignature(0x123..., ""); // 會失敗！

// ✅ 正確做法 - 使用 Factory 部署的 RWA
address rwa = factory.deployedRWAs(0);
factory.mintWithSignature(rwa, "");
```

---

## 📞 需要更多幫助？

如果以上都檢查過了還是有問題，請提供：
1. Factory 合約地址
2. RWA 合約地址
3. 嘗試 mint 的用戶地址
4. 交易 hash

這樣我可以更具體地幫助你診斷問題！
