# 画像配置ルール

説明用 Markdown の画像は、`docs/images/<md名>/` に分けて管理します。

## 例

- `docs/chara.md` の画像: `docs/images/chara/`
- `docs/index.md` の画像: `docs/images/index/`
- `docs/boot.md` の画像: `docs/images/boot/`
- `docs/install.md` の画像: `docs/images/install/`
- `docs/installfiles.md` の画像: `docs/images/installfiles/`

## Markdown からの参照

`docs/chara.md` なら次のように相対パスで書きます。

```md
![キャラ一覧](images/chara/characters-overview.png)
```

この形式なら、`.md` ごとに画像を分離しつつ Git 管理もしやすくなります。
