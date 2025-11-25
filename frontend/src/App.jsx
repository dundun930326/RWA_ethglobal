import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import './App.css'

// 合约 ABI (简化版，只包含我们需要的方法)
const RWA_ABI = [
  "function tokenURI(uint256 tokenId) view returns (string)",
  "function totalSupply() view returns (uint256)"
]

const FACTORY_ABI = [
  "function getDeployedRWAs() view returns (address[])",
  "function deployedRWAs(uint256) view returns (address)"
]

function App() {
  const [provider, setProvider] = useState(null)
  const [signer, setSigner] = useState(null)
  const [account, setAccount] = useState(null)
  const [factoryAddress, setFactoryAddress] = useState('')
  const [rwaAddresses, setRwaAddresses] = useState([])
  const [nfts, setNfts] = useState([])
  const [loading, setLoading] = useState(false)

  // 连接钱包
  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum)
        const accounts = await provider.send("eth_requestAccounts", [])
        const signer = await provider.getSigner()
        
        setProvider(provider)
        setSigner(signer)
        setAccount(accounts[0])
      } catch (error) {
        console.error('连接钱包失败:', error)
        alert('连接钱包失败，请确保已安装 MetaMask')
      }
    } else {
      alert('请安装 MetaMask 钱包')
    }
  }

  // 获取所有 RWA 合约地址
  const fetchRWAs = async () => {
    if (!provider || !factoryAddress) return
    
    try {
      setLoading(true)
      const factory = new ethers.Contract(factoryAddress, FACTORY_ABI, provider)
      const addresses = await factory.getDeployedRWAs()
      setRwaAddresses(addresses)
      
      // 获取所有 NFT 数据
      await fetchAllNFTs(addresses)
    } catch (error) {
      console.error('获取 RWA 合约失败:', error)
      alert('获取合约数据失败，请检查合约地址是否正确')
    } finally {
      setLoading(false)
    }
  }

  // 获取所有 NFT 的 metadata
  const fetchAllNFTs = async (addresses) => {
    const allNFTs = []
    
    for (const rwaAddress of addresses) {
      try {
        const rwa = new ethers.Contract(rwaAddress, RWA_ABI, provider)
        
        // 获取总供应量
        let totalSupply
        try {
          totalSupply = await rwa.totalSupply()
        } catch (error) {
          console.error('获取 totalSupply 失败:', error)
          totalSupply = ethers.toBigInt(0)
        }
        
        // 获取每个 token 的 metadata (tokenId 从 1 开始)
        for (let i = 1; i <= Number(totalSupply); i++) {
          try {
            const tokenId = ethers.toBigInt(i)
            const uri = await rwa.tokenURI(tokenId)
            const metadata = await fetchMetadata(uri)
            
            allNFTs.push({
              rwaAddress,
              tokenId: tokenId.toString(),
              uri,
              metadata
            })
          } catch (error) {
            // 如果某个 tokenId 不存在，跳过
            console.error(`获取 token ${i} 失败:`, error)
          }
        }
      } catch (error) {
        console.error(`获取 RWA ${rwaAddress} 失败:`, error)
      }
    }
    
    setNfts(allNFTs)
  }

  // 获取 metadata JSON
  const fetchMetadata = async (uri) => {
    try {
      // 处理 IPFS URI
      const url = uri.startsWith('ipfs://') 
        ? `https://ipfs.io/ipfs/${uri.replace('ipfs://', '')}`
        : uri
      
      const response = await fetch(url)
      if (response.ok) {
        return await response.json()
      }
    } catch (error) {
      console.error('获取 metadata 失败:', error)
    }
    return null
  }

  useEffect(() => {
    if (provider && factoryAddress) {
      fetchRWAs()
    }
  }, [provider, factoryAddress])

  return (
    <div className="app">
      <h1>RWA NFT Gallery</h1>
      
      {!account ? (
        <div className="connect-section">
          <button onClick={connectWallet}>连接钱包</button>
        </div>
      ) : (
        <div className="main-section">
          <div className="info">
            <p>已连接: {account.slice(0, 6)}...{account.slice(-4)}</p>
          </div>
          
          <div className="factory-input">
            <input
              type="text"
              placeholder="输入 Factory 合约地址"
              value={factoryAddress}
              onChange={(e) => setFactoryAddress(e.target.value)}
            />
            <button onClick={fetchRWAs} disabled={loading}>
              {loading ? '加载中...' : '获取 NFT'}
            </button>
          </div>

          {rwaAddresses.length > 0 && (
            <div className="rwa-info">
              <h2>RWA 合约数量: {rwaAddresses.length}</h2>
            </div>
          )}

          {nfts.length > 0 && (
            <div className="nft-grid">
              <h2>NFT 列表 ({nfts.length})</h2>
              <div className="grid">
                {nfts.map((nft, index) => (
                  <div key={index} className="nft-card">
                    {nft.metadata?.image && (
                      <img 
                        src={nft.metadata.image.startsWith('ipfs://') 
                          ? `https://ipfs.io/ipfs/${nft.metadata.image.replace('ipfs://', '')}`
                          : nft.metadata.image
                        } 
                        alt={nft.metadata.name || 'NFT'} 
                        onError={(e) => {
                          e.target.style.display = 'none'
                        }}
                      />
                    )}
                    <div className="nft-info">
                      <h3>{nft.metadata?.name || `Token #${nft.tokenId}`}</h3>
                      {nft.metadata?.description && (
                        <p className="description">{nft.metadata.description}</p>
                      )}
                      <div className="nft-details">
                        <p><strong>Token ID:</strong> {nft.tokenId}</p>
                        <p><strong>RWA 合约:</strong> {nft.rwaAddress.slice(0, 6)}...{nft.rwaAddress.slice(-4)}</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {!loading && factoryAddress && nfts.length === 0 && rwaAddresses.length === 0 && (
            <p className="no-data">暂无 NFT 数据</p>
          )}
        </div>
      )}
    </div>
  )
}

export default App
