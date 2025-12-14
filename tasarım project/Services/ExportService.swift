//
//  ExportService.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import UIKit
import PDFKit

class ExportService {
    static let shared = ExportService()
    
    private init() {}
    
    // MARK: - CSV Export
    
    func exportTradesToCSV(_ trades: [Trade]) -> String {
        var csv = "Tarih,Coin,İşlem Tipi,Miktar,Fiyat,Toplam Tutar\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        
        for trade in trades {
            let date = formatter.string(from: trade.timestamp)
            let type = trade.type == .buy ? "Alış" : "Satış"
            let total = trade.amount * trade.price
            
            csv += "\(date),\(trade.coinSymbol),\(type),\(trade.amount),\(trade.price),\(total)\n"
        }
        
        return csv
    }
    
    func exportPortfolioToCSV(_ portfolio: [String: Double], coins: [Coin]) -> String {
        var csv = "Coin,Miktar,Güncel Fiyat,Toplam Değer\n"
        
        for (symbol, amount) in portfolio {
            if let coin = coins.first(where: { $0.symbol == symbol }) {
                let totalValue = amount * coin.price
                csv += "\(symbol),\(amount),\(coin.price),\(totalValue)\n"
            }
        }
        
        return csv
    }
    
    func exportTradingStatisticsToCSV(_ statistics: TradingStatistics) -> String {
        var csv = "Metrik,Değer\n"
        csv += "Toplam İşlem,\(statistics.totalTrades)\n"
        csv += "Kârlı İşlem,\(statistics.winningTrades)\n"
        csv += "Zararlı İşlem,\(statistics.losingTrades)\n"
        csv += "Başarı Oranı,\(String(format: "%.2f", statistics.winRate))%\n"
        csv += "Toplam Kâr/Zarar,\(String(format: "%.2f", statistics.totalProfit))\n"
        csv += "Ortalama Kâr,\(String(format: "%.2f", statistics.averageProfit))\n"
        csv += "Profit Factor,\(String(format: "%.2f", statistics.profitFactor))\n"
        if let coin = statistics.mostProfitableCoin {
            csv += "En Kârlı Coin,\(coin)\n"
        }
        return csv
    }
    
    // MARK: - PDF Export
    
    func exportTradesToPDF(_ trades: [Trade], user: User) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "EduTrade",
            kCGPDFContextAuthor: SettingsViewModel().settings.userName,
            kCGPDFContextTitle: "Trading Raporu"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 72
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.label
            ]
            let title = "Trading Raporu"
            title.draw(at: CGPoint(x: 72, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            dateFormatter.locale = Locale(identifier: "tr_TR")
            let dateString = "Tarih: \(dateFormatter.string(from: Date()))"
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel
            ]
            dateString.draw(at: CGPoint(x: 72, y: yPosition), withAttributes: dateAttributes)
            yPosition += 30
            
            // Summary
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.label
            ]
            let summary = """
            Toplam İşlem: \(trades.count)
            Bakiye: $\(String(format: "%.2f", user.balance))
            """
            summary.draw(at: CGPoint(x: 72, y: yPosition), withAttributes: summaryAttributes)
            yPosition += 50
            
            // Table header
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: UIColor.label
            ]
            let headers = ["Tarih", "Coin", "Tip", "Miktar", "Fiyat", "Toplam"]
            var xPosition: CGFloat = 72
            let columnWidth: CGFloat = 100
            
            for header in headers {
                header.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: headerAttributes)
                xPosition += columnWidth
            }
            yPosition += 25
            
            // Table rows
            let rowAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.label
            ]
            
            let dateFormatter2 = DateFormatter()
            dateFormatter2.dateStyle = .short
            dateFormatter2.timeStyle = .short
            
            for trade in trades.prefix(20) { // Limit to 20 trades per page
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = 72
                }
                
                xPosition = 72
                let date = dateFormatter2.string(from: trade.timestamp)
                let type = trade.type == .buy ? "Alış" : "Satış"
                let total = trade.amount * trade.price
                
                let rowData = [date, trade.coinSymbol, type, String(format: "%.4f", trade.amount), String(format: "%.2f", trade.price), String(format: "%.2f", total)]
                
                for data in rowData {
                    data.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: rowAttributes)
                    xPosition += columnWidth
                }
                
                yPosition += 20
            }
        }
        
        return data
    }
    
    func exportPortfolioToPDF(_ portfolio: [String: Double], coins: [Coin], user: User) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "EduTrade",
            kCGPDFContextAuthor: SettingsViewModel().settings.userName,
            kCGPDFContextTitle: "Portföy Raporu"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 72
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.label
            ]
            let title = "Portföy Raporu"
            title.draw(at: CGPoint(x: 72, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Summary
            var totalValue = 0.0
            for (symbol, amount) in portfolio {
                if let coin = coins.first(where: { $0.symbol == symbol }) {
                    totalValue += amount * coin.price
                }
            }
            
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.label
            ]
            let summary = """
            Toplam Portföy Değeri: $\(String(format: "%.2f", totalValue))
            Coin Sayısı: \(portfolio.count)
            """
            summary.draw(at: CGPoint(x: 72, y: yPosition), withAttributes: summaryAttributes)
            yPosition += 50
            
            // Table header
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: UIColor.label
            ]
            let headers = ["Coin", "Miktar", "Fiyat", "Değer"]
            var xPosition: CGFloat = 72
            let columnWidth: CGFloat = 150
            
            for header in headers {
                header.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: headerAttributes)
                xPosition += columnWidth
            }
            yPosition += 25
            
            // Table rows
            let rowAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.label
            ]
            
            for (symbol, amount) in portfolio.sorted(by: { $0.key < $1.key }) {
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = 72
                }
                
                if let coin = coins.first(where: { $0.symbol == symbol }) {
                    xPosition = 72
                    let value = amount * coin.price
                    
                    let rowData = [symbol, String(format: "%.4f", amount), String(format: "%.2f", coin.price), String(format: "%.2f", value)]
                    
                    for data in rowData {
                        data.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: rowAttributes)
                        xPosition += columnWidth
                    }
                    
                    yPosition += 20
                }
            }
        }
        
        return data
    }
    
    // MARK: - Share
    
    func shareCSV(_ csv: String, fileName: String, from viewController: UIViewController) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).csv")
        
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            viewController.present(activityVC, animated: true)
        } catch {
            print("CSV export error: \(error)")
        }
    }
    
    func sharePDF(_ pdfData: Data, fileName: String, from viewController: UIViewController) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).pdf")
        
        do {
            try pdfData.write(to: tempURL)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            viewController.present(activityVC, animated: true)
        } catch {
            print("PDF export error: \(error)")
        }
    }
}

