# テスト環境について

このディレクトリにはRSpecを使用したテストファイルが配置されています。

## 構成

- `spec_helper.rb` - RSpecの基本設定
- `support/lib_helper.rb` - libディレクトリのファイルを読み込むヘルパー
- `example_spec.rb` - 設定動作確認用のサンプルテスト（実際のテスト作成後は削除可能）
- `lib/` - libディレクトリのコンポーネント用のテストファイル置き場

## テストの実行方法

```bash
# 全てのテストを実行
bundle exec rspec

# 特定のファイルのテストを実行
bundle exec rspec spec/example_spec.rb

# Rakeタスクを使用
bundle exec rake spec
# または
bundle exec rake test
```

## テストファイルの作成

libディレクトリのクラスをテストする場合:

```ruby
# frozen_string_literal: true

require 'spec_helper'
require 'support/lib_helper'

RSpec.describe YourClass do
  # テスト内容
end
```

## 注意

- 既存のソースコードに対するテストの実装は要件に含まれていません
- このセットアップはテスト環境の基盤のみを提供します