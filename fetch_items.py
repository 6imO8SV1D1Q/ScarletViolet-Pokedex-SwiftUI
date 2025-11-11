#!/usr/bin/env python3
"""
Fetch item data from PokeAPI and format it for the app.
This script fetches held items (battle items, berries, type-enhancing items, etc.)
and saves them in JSON format.
"""

import requests
import json
import time
from typing import Dict, List, Any, Optional

BASE_URL = "https://pokeapi.co/api/v2"

# Item categories we want to include (competitive battle items)
RELEVANT_CATEGORIES = [
    "stat-boosts",           # きあいのタスキ、いのちのたま等
    "effort-drop",           # 努力値を下げるアイテム
    "medicine",              # 回復アイテム
    "other",                 # その他バトル用アイテム
    "in-a-pinch",           # ピンチベリー
    "type-protection",       # タイプ耐性ベリー
    "baking-only",          # その他のベリー
    "type-enhancement",     # タイプ強化アイテム
    "choice",               # こだわり系
    "effort-training",      # 努力値トレーニング
    "bad-held-items",       # マイナス効果
    "training",             # トレーニング用
    "plates",               # プレート
    "species-specific",     # ポケモン専用アイテム
    "mega-stones",          # メガストーン
    "memories",             # メモリ
    "z-crystals",           # Zクリスタル
    "mulch",                # マルチ
    "special-balls",        # 特殊ボール
    "standard-balls",       # 標準ボール
    "dex-completion",       # 図鑑完成用
    "scarves",              # スカーフ
    "all-mail",             # メール
    "vitamins",             # タウリン等
    "healing",              # 回復アイテム
    "pp-recovery",          # PP回復
    "revival",              # 復活アイテム
    "status-cures",         # 状態異常回復
    "collectibles",         # 収集品
    "evolution",            # 進化アイテム
    "spelunking",           # 探検用
    "held-items",           # 持ち物全般
    "loot",                 # 戦利品
    "all-machines",         # わざマシン
    "flutes",               # フルート
    "apricorn-balls",       # ぼんぐりボール
    "apricorn-box",         # ぼんぐりケース
    "data-cards",           # データカード
    "jewels",               # ジュエル
    "miracle-shooter",      # ミラクルシューター
    "mega-stones",          # メガストーン
    "z-crystals",           # Zクリスタル
]

def fetch_with_retry(url: str, max_retries: int = 3) -> Optional[Dict]:
    """Fetch data from URL with retry logic."""
    for attempt in range(max_retries):
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"  ⚠️  Attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)  # Exponential backoff
            else:
                print(f"  ❌ Failed to fetch {url} after {max_retries} attempts")
                return None

def get_japanese_name(names: List[Dict]) -> str:
    """Extract Japanese name from names array."""
    for name_entry in names:
        if name_entry.get("language", {}).get("name") == "ja":
            return name_entry.get("name", "")
    return ""

def get_japanese_effect(effect_entries: List[Dict]) -> str:
    """Extract Japanese effect description."""
    for effect_entry in effect_entries:
        if effect_entry.get("language", {}).get("name") == "ja":
            return effect_entry.get("short_effect", effect_entry.get("effect", ""))
    return ""

def get_english_effect(effect_entries: List[Dict]) -> str:
    """Extract English effect description."""
    for effect_entry in effect_entries:
        if effect_entry.get("language", {}).get("name") == "en":
            return effect_entry.get("short_effect", effect_entry.get("effect", ""))
    return ""

def fetch_item_categories() -> List[Dict]:
    """Fetch all item categories from PokeAPI."""
    print("📦 Fetching item categories...")
    url = f"{BASE_URL}/item-category"
    data = fetch_with_retry(url)

    if not data:
        return []

    categories = []
    for category_ref in data.get("results", []):
        category_data = fetch_with_retry(category_ref["url"])
        if category_data:
            categories.append(category_data)
            time.sleep(0.1)  # Rate limiting

    print(f"✅ Found {len(categories)} categories")
    return categories

def fetch_items_from_categories(categories: List[Dict]) -> List[Dict]:
    """Fetch all items from relevant categories."""
    print("\n🔍 Fetching items from categories...")

    all_items = {}  # Use dict to deduplicate

    for category in categories:
        category_name = category.get("name", "")
        items_in_category = category.get("items", [])

        print(f"\n📂 Category: {category_name} ({len(items_in_category)} items)")

        for item_ref in items_in_category:
            item_name = item_ref.get("name", "")
            item_url = item_ref.get("url", "")

            # Skip if already fetched
            if item_name in all_items:
                continue

            print(f"  📥 Fetching {item_name}...")
            item_data = fetch_with_retry(item_url)

            if item_data:
                # Extract relevant information
                item_id = item_data.get("id")
                names = item_data.get("names", [])
                effect_entries = item_data.get("effect_entries", [])
                flavor_text_entries = item_data.get("flavor_text_entries", [])
                sprites = item_data.get("sprites", {})
                category_ref = item_data.get("category", {})

                name_ja = get_japanese_name(names)
                effect = get_english_effect(effect_entries)
                effect_ja = get_japanese_effect(effect_entries)

                # Get flavor text if no effect description
                if not effect_ja and flavor_text_entries:
                    for flavor in flavor_text_entries:
                        if flavor.get("language", {}).get("name") == "ja":
                            effect_ja = flavor.get("text", "")
                            break

                if not effect and flavor_text_entries:
                    for flavor in flavor_text_entries:
                        if flavor.get("language", {}).get("name") == "en":
                            effect = flavor.get("text", "")
                            break

                item_entry = {
                    "id": item_id,
                    "name": item_name,
                    "nameJa": name_ja,
                    "category": category_name,
                    "description": effect,
                    "descriptionJa": effect_ja,
                    "spriteUrl": sprites.get("default", ""),
                    "cost": item_data.get("cost", 0)
                }

                all_items[item_name] = item_entry

            time.sleep(0.2)  # Rate limiting

    return list(all_items.values())

def save_items_json(items: List[Dict], output_path: str):
    """Save items to JSON file."""
    print(f"\n💾 Saving {len(items)} items to {output_path}...")

    # Sort by ID
    items_sorted = sorted(items, key=lambda x: x.get("id", 0))

    output_data = {
        "schemaVersion": 1,
        "items": items_sorted
    }

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)

    print(f"✅ Saved successfully!")

def main():
    """Main execution function."""
    print("🚀 Starting item data fetch from PokeAPI...\n")

    # Fetch categories
    categories = fetch_item_categories()

    if not categories:
        print("❌ Failed to fetch categories")
        return

    # Fetch items
    items = fetch_items_from_categories(categories)

    if not items:
        print("❌ No items fetched")
        return

    print(f"\n📊 Total items fetched: {len(items)}")

    # Save to JSON
    output_path = "/home/user/ScarletViolet-Pokedex-SwiftUI/items_data.json"
    save_items_json(items, output_path)

    print("\n✨ Done!")

if __name__ == "__main__":
    main()
