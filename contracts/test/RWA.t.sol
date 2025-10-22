// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 匯入 Foundry 的標準測試工具
import "forge-std/Test.sol";
// 匯入我們要測試的合約
import "../src/RWA.sol";

// --- 這是新加入的 ---
// 為了能存取 Ownable 的自定義錯誤
import "openzeppelin-contracts/contracts/access/Ownable.sol"; 

contract RWATest is Test {
    
    // 宣告合約和地址的狀態變數
    RWA public rwaToken;
    address public deployer; // 部署者 (也就是 Owner)
    address public user;     // 一個隨機的使用者

    /**
     * @dev 在每個測試案例 (test function) 執行前都會先執行的設定函數
     */
    function setUp() public {
        // 1. 設定地址
        deployer = msg.sender; // 在 Foundry 測試中，msg.sender 預設是 test contract 自己
        user = address(0x1);  // 隨便選一個地址當作一般使用者

        // 2. 部署合約
        // 我們 "prank" (偽裝) 成 deployer 來部署，
        // 這樣 RWA 合約的 constructor() 就會把 'deployer' 設為 Owner
        vm.prank(deployer);
        rwaToken = new RWA();
    }

    /**
     * @dev 測試案例 1: 測試 Owner 成功鑄造 (Happy Path)
     */
    function test_OwnerCanMint() public {
        string memory testURI = "ipfs://QmWtDqfGgJd1L9zNrmXAxwtr5kSKqsXbuD1nMAmYjX2UoT";
        
        // 1. 偽裝成 'deployer' (Owner) 來呼叫 safeMint
        vm.prank(deployer);
        uint256 tokenId = rwaToken.safeMint(user, testURI);

        // 2. 斷言 (Assert) - 檢查狀態是否如預期 (已加入 unicode 修正)
        assertEq(tokenId, 1, unicode"Token ID 應該是 1 (因為是第一個)");
        assertEq(rwaToken.ownerOf(tokenId), user, unicode"NFT 的擁有者應該是 'user'");
        assertEq(rwaToken.balanceOf(user), 1, unicode"'user' 的餘額應該是 1");
        assertEq(rwaToken.tokenURI(tokenId), testURI, unicode"Token URI 應該被正確設定");
    }

    /**
     * @dev 測試案例 2: 測試非 Owner 鑄造失敗
     */
    function test_Fail_NonOwnerCannotMint() public {
        // --- 這是關鍵修正 ---
        // 我們預期它會丟出 Ownable 合約的 'OwnableUnauthorizedAccount' 自定義錯誤
        // 並且錯誤報告的地址 (sender) 應該是 'user'
        // 注意：我們現在是呼叫 "Ownable." 而不是 "RWA."
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));

        // 2. 偽裝成 'user' (非 Owner) 去嘗試呼叫 safeMint
        vm.prank(user);
        rwaToken.safeMint(user, "ipfs://fail_uri");
        
        // 如果上面那行沒有 revert，这个测试就会失败
    }

    /**
     * @dev 測試案例 3: 測試 token ID 會正確遞增
     */
    function test_TokenIdIncrements() public {
        vm.prank(deployer);
        uint256 tokenId1 = rwaToken.safeMint(user, "uri1");
        
        vm.prank(deployer);
        uint256 tokenId2 = rwaToken.safeMint(user, "uri2");

        // (已加入 unicode 修正)
        assertEq(tokenId1, 1, unicode"第一個 token ID 應該是 1");
        assertEq(tokenId2, 2, unicode"第二個 token ID 應該是 2");
    }
}