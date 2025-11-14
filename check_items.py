import json

with open('/home/user/ScarletViolet-Pokedex-SwiftUI/ScarletViolet-Pokedex-SwiftUI/ScarletViolet-Pokedex-SwiftUI/Resources/PreloadedData/items_v5.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

categories = {}
for item in data['items']:
    cat = item['category']
    if cat not in categories:
        categories[cat] = []
    categories[cat].append(item['nameJa'])

print(f"総アイテム数: {len(data['items'])}\n")
print("カテゴリ別アイテム数:")
for cat, items in sorted(categories.items()):
    print(f"  {cat}: {len(items)}個")

print("\n各カテゴリのアイテム例:")
for cat, items in sorted(categories.items()):
    print(f"\n{cat}:")
    for item in items[:5]:
        print(f"  - {item}")
