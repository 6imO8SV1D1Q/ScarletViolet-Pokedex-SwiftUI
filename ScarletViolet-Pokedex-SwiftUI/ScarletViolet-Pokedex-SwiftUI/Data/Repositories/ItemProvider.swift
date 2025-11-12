//
//  ItemProvider.swift
//  Pokedex
//
//  Created on 2025-11-01.
//

import Foundation

/// アイテムデータを提供するプロバイダー
///
/// プリバンドルされたJSONファイル（items_v6.json）からアイテム情報を読み込み、
/// メモリキャッシュで管理します。
///
/// ## 主な責務
/// - items_v6.jsonの読み込み
/// - アイテムデータのキャッシュ管理
/// - ID/名前/カテゴリーによる検索
///
/// ## キャッシュ戦略
/// - アプリ起動時に全データを読み込み
/// - メモリキャッシュ（ItemCache）を使用
final class ItemProvider: ItemProviderProtocol {
    private let cache: ItemCache
    private let bundle: Bundle

    /// イニシャライザ
    /// - Parameters:
    ///   - cache: アイテムキャッシュ
    ///   - bundle: JSONファイルを含むバンドル（テスト用）
    init(cache: ItemCache = ItemCache(), bundle: Bundle = .main) {
        self.cache = cache
        self.bundle = bundle
    }

    /// 全アイテムのリストを取得
    /// - Returns: アイテム情報のリスト（ID順にソート済み）
    /// - Throws: データ取得時のエラー
    func fetchAllItems() async throws -> [ItemEntity] {
        // TEMPORARY DEBUG: Skip cache and always load from JSON
        print("🔍 [ItemProvider] Skipping cache, loading from JSON...")

        // JSONファイルから読み込み
        let items = try loadItemsFromJSON()
        print("📦 [ItemProvider] Loaded from JSON: \(items.count) items")

        if items.isEmpty {
            print("⚠️ [ItemProvider] JSON returned 0 items!")
        } else {
            print("📦 [ItemProvider] Sample items: \(items.prefix(3).map { "\($0.nameJa) (category: \($0.category))" })")
        }

        // キャッシュに保存
        await cache.setAll(items: items)
        return items
    }

    /// IDでアイテムを取得
    /// - Parameter itemId: アイテムID
    /// - Returns: アイテム情報
    /// - Throws: データ取得時のエラー
    func fetchItem(id itemId: Int) async throws -> ItemEntity {
        // キャッシュチェック
        if let cached = await cache.get(itemId: itemId) {
            return cached
        }

        // 全アイテムを読み込んでからキャッシュ検索
        _ = try await fetchAllItems()

        guard let item = await cache.get(itemId: itemId) else {
            throw ItemProviderError.itemNotFoundById(itemId)
        }

        return item
    }

    /// 名前でアイテムを取得
    /// - Parameter itemName: アイテム名（英語、ケバブケース）
    /// - Returns: アイテム情報
    /// - Throws: データ取得時のエラー
    func fetchItem(name itemName: String) async throws -> ItemEntity {
        // キャッシュチェック
        if let cached = await cache.get(itemName: itemName) {
            return cached
        }

        // 全アイテムを読み込んでからキャッシュ検索
        _ = try await fetchAllItems()

        guard let item = await cache.get(itemName: itemName) else {
            throw ItemProviderError.itemNotFoundByName(itemName)
        }

        return item
    }

    /// カテゴリーでアイテムをフィルタリング
    /// - Parameter category: カテゴリー名（例: "held-item"）
    /// - Returns: 該当カテゴリーのアイテムリスト
    /// - Throws: データ取得時のエラー
    func fetchItems(category: String) async throws -> [ItemEntity] {
        let allItems = try await fetchAllItems()
        return allItems.filter { $0.category == category }
    }

    // MARK: - Private Methods

    /// JSONファイルからアイテムデータを読み込む
    private func loadItemsFromJSON() throws -> [ItemEntity] {
        print("🔍 [ItemProvider] Bundle path: \(bundle.bundlePath)")
        print("🔍 [ItemProvider] Resource path: \(bundle.resourcePath ?? "nil")")

        // List all files in bundle to debug
        if let resourcePath = bundle.resourcePath {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                print("📂 [ItemProvider] Bundle contents: \(contents)")

                // Check if PreloadedData directory exists
                let preloadedPath = (resourcePath as NSString).appendingPathComponent("PreloadedData")
                if FileManager.default.fileExists(atPath: preloadedPath) {
                    let preloadedContents = try FileManager.default.contentsOfDirectory(atPath: preloadedPath)
                    print("📂 [ItemProvider] PreloadedData contents: \(preloadedContents)")
                } else {
                    print("❌ [ItemProvider] PreloadedData directory does not exist")
                }

                // Check if Resources directory exists
                let resourcesPath = (resourcePath as NSString).appendingPathComponent("Resources")
                if FileManager.default.fileExists(atPath: resourcesPath) {
                    let resourcesContents = try FileManager.default.contentsOfDirectory(atPath: resourcesPath)
                    print("📂 [ItemProvider] Resources contents: \(resourcesContents)")

                    let resourcesPreloadedPath = (resourcesPath as NSString).appendingPathComponent("PreloadedData")
                    if FileManager.default.fileExists(atPath: resourcesPreloadedPath) {
                        let resourcesPreloadedContents = try FileManager.default.contentsOfDirectory(atPath: resourcesPreloadedPath)
                        print("📂 [ItemProvider] Resources/PreloadedData contents: \(resourcesPreloadedContents)")
                    }
                } else {
                    print("❌ [ItemProvider] Resources directory does not exist")
                }
            } catch {
                print("❌ [ItemProvider] Failed to list directory: \(error)")
            }
        }

        // Try multiple possible locations for the JSON file
        var url: URL?

        // Method 1: Bundle root (Xcode Cloud flattens directory structure)
        url = bundle.url(forResource: "items_v6", withExtension: "json")
        if url != nil {
            print("✅ [ItemProvider] Found via Method 1: bundle root")
        }

        // Method 2: With subdirectory parameter
        if url == nil {
            url = bundle.url(forResource: "items_v6", withExtension: "json", subdirectory: "PreloadedData")
            if url != nil {
                print("✅ [ItemProvider] Found via Method 2: subdirectory parameter")
            }
        }

        // Method 3: With path in resource name
        if url == nil {
            url = bundle.url(forResource: "PreloadedData/items_v6", withExtension: "json")
            if url != nil {
                print("✅ [ItemProvider] Found via Method 3: path in resource name")
            }
        }

        // Method 4: With full path including Resources
        if url == nil {
            url = bundle.url(forResource: "Resources/PreloadedData/items_v6", withExtension: "json")
            if url != nil {
                print("✅ [ItemProvider] Found via Method 4: full path with Resources")
            }
        }

        guard let fileURL = url else {
            print("❌ [ItemProvider] items_v6.json not found in bundle")
            throw ItemProviderError.fileNotFound
        }

        print("📁 [ItemProvider] Loading from: \(fileURL.path)")
        let data = try Data(contentsOf: fileURL)
        print("📊 [ItemProvider] Data size: \(data.count) bytes")

        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)

        print("📄 [ItemProvider] JSON schema version: \(response.schemaVersion)")
        print("📦 [ItemProvider] JSON items count: \(response.items.count)")

        // ID順にソート
        return response.items.sorted { $0.id < $1.id }
    }
}

// MARK: - JSON Response Model

/// items_v6.jsonのレスポンス構造
private struct ItemsResponse: Codable {
    let schemaVersion: Int
    let items: [ItemEntity]
}

// MARK: - Errors

/// ItemProviderのエラー
enum ItemProviderError: LocalizedError {
    case fileNotFound
    case itemNotFoundById(Int)
    case itemNotFoundByName(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "items_v6.json file not found"
        case .itemNotFoundById(let id):
            return "Item not found: id=\(id)"
        case .itemNotFoundByName(let name):
            return "Item not found: name=\(name)"
        }
    }
}
