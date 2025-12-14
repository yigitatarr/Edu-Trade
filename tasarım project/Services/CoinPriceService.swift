//
//  CoinPriceService.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import Combine

class CoinPriceService: ObservableObject {
    static let shared = CoinPriceService()
    
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 30 // 30 saniyede bir güncelle
    
    // CoinGecko API coin ID mapping (symbol -> CoinGecko ID)
    private let coinIdMapping: [String: String] = [
        "BTC": "bitcoin",
        "ETH": "ethereum",
        "ADA": "cardano",
        "BNB": "binance-coin",
        "SOL": "solana",
        "MATIC": "matic-network",
        "LINK": "chainlink",
        "LTC": "litecoin",
        "XRP": "ripple",
        "DOT": "polkadot",
        "AVAX": "avalanche-2",
        "UNI": "uniswap",
        "DOGE": "dogecoin",
        "SHIB": "shiba-inu",
        "TRX": "tron",
        "ATOM": "cosmos",
        "ETC": "ethereum-classic",
        "XLM": "stellar",
        "XMR": "monero",
        "ALGO": "algorand",
        "VET": "vechain",
        "FIL": "filecoin",
        "SAND": "the-sandbox",
        "MANA": "decentraland",
        "AXS": "axie-infinity",
        "AAVE": "aave",
        "MKR": "maker",
        "CETH": "compound-ether",
        "CRV": "curve-dao-token",
        "YFI": "yearn-finance",
        "SUSHI": "sushi",
        "1INCH": "1inch",
        "NEAR": "near",
        "FTM": "fantom",
        "ONE": "harmony",
        "THETA": "theta-token",
        "BAT": "basic-attention-token",
        "ENJ": "enjincoin",
        "GALA": "gala",
        "CHZ": "chiliz",
        "FLOW": "flow",
        "XTZ": "tezos",
        "EOS": "eos",
        "DASH": "dash",
        "ZEC": "zcash",
        "BCH": "bitcoin-cash",
        "WBTC": "wrapped-bitcoin",
        "USDT": "tether",
        "USDC": "usd-coin",
        "DAI": "dai",
        "OKB": "okb",
        "APT": "aptos",
        "ARB": "arbitrum",
        "OP": "optimism",
        "IMX": "immutable-x",
        "RENDER": "render-token",
        "INJ": "injective-protocol",
        "HBAR": "hedera-hashgraph",
        "GRT": "the-graph",
        "STX": "stacks",
        "CELO": "celo",
        "MINA": "mina-protocol",
        "LRC": "loopring",
        "QNT": "quant-network",
        "EGLD": "multiversx",
        "XRD": "radix",
        "KAVA": "kava",
        "ZIL": "zilliqa",
        "ICX": "icon",
        "ONT": "ontology",
        "WAVES": "waves",
        "IOTX": "iotex",
        "ROSE": "oasis-network",
        "CAKE": "pancakeswap-token",
        "COMP": "compound-governance-token",
        "ZRX": "0x",
        "KNC": "kyber-network-crystal",
        "REN": "ren",
        "UMA": "uma",
        "BAND": "band-protocol",
        "API3": "api3",
        "FET": "fetch-ai",
        "OCEAN": "ocean-protocol",
        "NMR": "numeraire",
        "AGIX": "singularitynet",
        "AI": "artificial-intelligence",
        "WLD": "worldcoin-wld",
        "TAO": "bittensor",
        "AKT": "akash-network",
        "LPT": "livepeer",
        "AR": "arweave",
        "STORJ": "storj",
        "SC": "siacoin",
        "HNT": "helium",
        "TFUEL": "theta-fuel",
        "AUDIO": "audius",
        "GODS": "gods-unchained",
        "ILV": "illuvium",
        "ALICE": "my-neighbor-alice",
        "ATLAS": "star-atlas",
        "TLM": "alien-worlds",
        "SLP": "smooth-love-potion",
        "GMT": "stepn",
        "MIM": "magic-internet-money",
        "FRAX": "frax",
        "LUSD": "liquity-usd",
        "UST": "terrausd",
        "TUSD": "true-usd",
        "PAX": "paxos-standard",
        "BUSD": "binance-usd",
        "GUSD": "gemini-dollar"
    ]
    
    // Reverse mapping (CoinGecko ID -> symbol)
    private var symbolMapping: [String: String] {
        var mapping: [String: String] = [:]
        for (symbol, id) in coinIdMapping {
            mapping[id] = symbol
        }
        return mapping
    }
    
    private init() {
        startAutoUpdate()
    }
    
    deinit {
        stopAutoUpdate()
    }
    
    // MARK: - Auto Update
    
    func startAutoUpdate() {
        stopAutoUpdate()
        
        // İlk güncellemeyi hemen yap
        updatePrices()
        
        // Sonra periyodik olarak güncelle
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updatePrices()
        }
    }
    
    func stopAutoUpdate() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Price Update
    
    func updatePrices(completion: ((Bool) -> Void)? = nil) {
        guard !isLoading else {
            completion?(false)
            return
        }
        
        isLoading = true
        
        // CoinGecko API endpoint - Extended data with market cap, volume, supply
        let coinIds = coinIdMapping.values.joined(separator: ",")
        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=\(coinIds)&vs_currencies=usd&include_24hr_change=true&include_market_cap=true&include_24hr_vol=true&include_last_updated_at=true"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            completion?(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Coin price update error: \(error.localizedDescription)")
                    let appError = AppError.networkError(error.localizedDescription)
                    ErrorHandler.shared.handle(appError)
                    completion?(false)
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    ErrorHandler.shared.handle(.dataLoadError)
                    completion?(false)
                    return
                }
                
                // Parse response and update coins
                var updatedCoins: [Coin] = []
                let symbolMap = self.symbolMapping
                
                for (coinId, coinData) in json {
                    guard let dataDict = coinData as? [String: Any],
                          let price = dataDict["usd"] as? Double else {
                        continue
                    }
                    
                    // Get extended data
                    let change24h = dataDict["usd_24h_change"] as? Double ?? 0.0
                    let marketCap = dataDict["usd_market_cap"] as? Double
                    let volume = dataDict["usd_24h_vol"] as? Double
                    
                    // Find symbol from coinId
                    if let symbol = symbolMap[coinId] {
                        // Find existing coin or create new one
                        if let existingCoin = DataManager.shared.coins.first(where: { $0.symbol == symbol }) {
                            var updatedCoin = existingCoin
                            updatedCoin.price = price
                            updatedCoin.change24h = change24h
                            updatedCoin.marketCap = marketCap
                            updatedCoin.totalVolume = volume
                            updatedCoins.append(updatedCoin)
                        } else {
                            // Create new coin if not found
                            var newCoin = Coin(
                                id: coinId,
                                symbol: symbol,
                                name: self.getCoinName(for: symbol),
                                price: price,
                                change24h: change24h
                            )
                            newCoin.marketCap = marketCap
                            newCoin.totalVolume = volume
                            updatedCoins.append(newCoin)
                        }
                    }
                }
                
                // Update DataManager with new prices
                if !updatedCoins.isEmpty {
                    // Preserve order of existing coins
                    var finalCoins: [Coin] = []
                    for existingCoin in DataManager.shared.coins {
                        if let updatedCoin = updatedCoins.first(where: { $0.symbol == existingCoin.symbol }) {
                            finalCoins.append(updatedCoin)
                        } else {
                            finalCoins.append(existingCoin)
                        }
                    }
                    
                    // Add any new coins that weren't in the original list
                    for updatedCoin in updatedCoins {
                        if !finalCoins.contains(where: { $0.symbol == updatedCoin.symbol }) {
                            finalCoins.append(updatedCoin)
                        }
                    }
                    
                    DataManager.shared.coins = finalCoins
                    self.lastUpdateTime = Date()
                    
                    // Check pending orders and price alerts when prices update
                    NotificationCenter.default.post(name: NSNotification.Name("CoinPricesUpdated"), object: nil)
                    
                    completion?(true)
                } else {
                    // If no updates, still mark as updated (API might be down, but we tried)
                    self.lastUpdateTime = Date()
                    completion?(false)
                }
            }
        }.resume()
    }
    
    private func getCoinName(for symbol: String) -> String {
        let names: [String: String] = [
            "BTC": "Bitcoin",
            "ETH": "Ethereum",
            "ADA": "Cardano",
            "BNB": "Binance Coin",
            "SOL": "Solana",
            "MATIC": "Polygon",
            "LINK": "Chainlink",
            "LTC": "Litecoin",
            "XRP": "Ripple",
            "DOT": "Polkadot",
            "AVAX": "Avalanche",
            "UNI": "Uniswap",
            "DOGE": "Dogecoin",
            "SHIB": "Shiba Inu",
            "TRX": "TRON",
            "ATOM": "Cosmos",
            "ETC": "Ethereum Classic",
            "XLM": "Stellar",
            "XMR": "Monero",
            "ALGO": "Algorand",
            "VET": "VeChain",
            "FIL": "Filecoin",
            "SAND": "The Sandbox",
            "MANA": "Decentraland",
            "AXS": "Axie Infinity",
            "AAVE": "Aave",
            "MKR": "Maker",
            "CETH": "Compound",
            "CRV": "Curve DAO",
            "YFI": "Yearn Finance",
            "SUSHI": "SushiSwap",
            "1INCH": "1inch",
            "NEAR": "NEAR Protocol",
            "FTM": "Fantom",
            "ONE": "Harmony",
            "THETA": "Theta Network",
            "BAT": "Basic Attention Token",
            "ENJ": "Enjin Coin",
            "GALA": "Gala",
            "CHZ": "Chiliz",
            "FLOW": "Flow",
            "XTZ": "Tezos",
            "EOS": "EOS",
            "DASH": "Dash",
            "ZEC": "Zcash",
            "BCH": "Bitcoin Cash",
            "WBTC": "Wrapped Bitcoin",
            "USDT": "Tether",
            "USDC": "USD Coin",
            "DAI": "Dai",
            "OKB": "OKB",
            "APT": "Aptos",
            "ARB": "Arbitrum",
            "OP": "Optimism",
            "IMX": "Immutable X",
            "RENDER": "Render",
            "INJ": "Injective",
            "HBAR": "Hedera",
            "GRT": "The Graph",
            "STX": "Stacks",
            "CELO": "Celo",
            "MINA": "Mina Protocol",
            "LRC": "Loopring",
            "QNT": "Quant",
            "EGLD": "MultiversX",
            "XRD": "Radix",
            "KAVA": "Kava",
            "ZIL": "Zilliqa",
            "ICX": "ICON",
            "ONT": "Ontology",
            "WAVES": "Waves",
            "IOTX": "IoTeX",
            "ROSE": "Oasis Network",
            "CAKE": "PancakeSwap",
            "COMP": "Compound",
            "ZRX": "0x Protocol",
            "KNC": "Kyber Network",
            "REN": "Ren",
            "UMA": "UMA",
            "BAND": "Band Protocol",
            "API3": "API3",
            "FET": "Fetch.ai",
            "OCEAN": "Ocean Protocol",
            "NMR": "Numeraire",
            "AGIX": "SingularityNET",
            "AI": "AI",
            "WLD": "Worldcoin",
            "TAO": "Bittensor",
            "AKT": "Akash Network",
            "LPT": "Livepeer",
            "AR": "Arweave",
            "STORJ": "Storj",
            "SC": "Siacoin",
            "HNT": "Helium",
            "TFUEL": "Theta Fuel",
            "AUDIO": "Audius",
            "GODS": "Gods Unchained",
            "ILV": "Illuvium",
            "ALICE": "My Neighbor Alice",
            "ATLAS": "Star Atlas",
            "TLM": "Alien Worlds",
            "SLP": "Smooth Love Potion",
            "GMT": "STEPN",
            "MIM": "Magic Internet Money",
            "FRAX": "Frax",
            "LUSD": "Liquity USD",
            "UST": "TerraUSD",
            "TUSD": "TrueUSD",
            "PAX": "Pax Dollar",
            "BUSD": "Binance USD",
            "GUSD": "Gemini Dollar"
        ]
        return names[symbol] ?? symbol
    }
    
    // MARK: - Manual Update
    
    func forceUpdate() {
        updatePrices()
    }
}

