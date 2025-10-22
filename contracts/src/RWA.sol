// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 匯入 OpenZeppelin 的合約
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title RWA (Real World Asset) Token
 * @dev 這是一個基礎的 ERC-721 NFT 合約，代表一個 RWA。
 * - 使用 ERC721URIStorage 來儲存每個 token 不同的 metadata URI。
 * - 使用 Ownable 來限制誰可以鑄造 (mint)。
 */
contract RWA is ERC721, ERC721URIStorage, Ownable {

    // --- 這裡是新的計數器 ---
    // 它會自動初始化為 0
    uint256 private _tokenIdCounter;
    
    /**
     * @dev 合約的建構子 (Constructor)。
     * 1. 設定 NFT 的名稱 ("Real World Asset") 和代號 ("RWA")。
     * 2. 將部署合約的地址 (msg.sender) 設為 "Owner" (擁有者)。
     */
    constructor() 
        ERC721("Real World Asset", "RWA")
        Ownable(msg.sender) // 將部署者設為擁有者
    {}

    /**
     * @dev 鑄造一個新的 RWA NFT。
     * - 只有合約的 Owner (擁有者) 才能呼叫此函數。
     * - "to": NFT 要發送到的地址。
     * - "uri": 指向此 NFT metadata (元資料) 的 JSON 檔案的 URI (通常是 IPFS 或 Arweave 連結)。
     * - 回傳值: 新鑄造的 NFT 的 Token ID。
     */
    function safeMint(address to, string memory uri) 
        public 
        onlyOwner // 確保只有 Owner 才能執行
        returns (uint256)
    {
        // --- 這裡是修改後的計數器邏輯 ---
        
        // 1. 讓計數器 +1 (第一次呼叫時，會從 0 變成 1)
        _tokenIdCounter++;
        
        // 2. 取得計數器當前的值作為新的 Token ID
        uint256 tokenId = _tokenIdCounter;
        
        // --- 修改結束 ---
        
        // 3. 執行 ERC721 的內部鑄造函數
        _mint(to, tokenId);
        
        // 4. 設定這個新 Token ID 對應的 metadata URI
        _setTokenURI(tokenId, uri);
        
        // 5. 回傳這個 neuen Token ID
        return tokenId;
    }

    // --- 以下是 OpenZeppelin 要求的覆寫 (Overrides) ---

    /**
     * @dev 覆寫 tokenURI 函數。
     * 因為我們同時繼承了 ERC721 和 ERC721URIStorage，Solidity 要求我們明確指定要用哪一個。
     * 我們使用 super.tokenURI() 來呼叫 ERC721URIStorage 的版本。
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev 覆寫 supportsInterface 函數。
     * (同上，為了解決多重繼承的技術性要求)
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}