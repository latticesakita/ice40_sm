# iCE40_SM

Lattice Propel を使用して RISC-V プロセッサを iCE40 Ultra Plus FPGA に実装したプロジェクトです。

---

## 🚀 プロジェクト概要

このプロジェクトは、低消費電力・小型 FPGA である **iCE40 Ultra Plus** 上に、RISC-V ベースの SoC を構築することを目的としています。Lattice Propel を活用して、ハードウェア設計とソフトウェア開発を統合的に行っています。

---

## 🔧 使用技術

- FPGA: Lattice iCE40 Ultra Plus  
- 開発ツール:
  - Lattice Propel（Builder: `ice40_sm.sbx`）
  - Lattice Radiant（Project: `ice40_sm.rdf`）
- プロセッサ: RISC-V  
- HDL: Verilog  
- IP パッケージ: `.ipk`（Propel の `ippack` を使用）

---

## 📦 カスタム IP

このプロジェクトでは、Propel に含まれる `ippack` ツールを使用して、独自の IP を作成・パッケージ化しています。

- IP フォルダ: `IP/`
- 主な IP:
  - `ahb_spsram_sm`
  - `gpio_ahbl`
  - `timer_ahbl`
  - `uart_ahbl`

---

## 📁 ディレクトリ構成

iCE40_SM/
├── dpram1024x8/
│   ├── constraints/
│   ├── misc/
│   ├── rtl/
│   └── testbench/
├── dpram2048x2_512x8/
│   ├── constraints/
│   ├── misc/
│   ├── rtl/
│   └── testbench/
├── ice40_sm/
│   ├── .impl/
│   ├── ice40_common/
│   └── lib/
│       ├── IPs/
│       ├── latticesemi.com/
│       └── personal/
├── IP/
│   ├── ahb_spsram_sm/
│   ├── gpio_ahbl/
│   ├── timer_ahbl/
│   └── uart_ahbl/
├── propel_ws/
│   └── ice40_sm/
│       ├── src/
│       └── Debug/
├── sge/
├── source/
├── tb/
├── verification/
└── impl_1/
---

## 🛠️ ビルド方法

1. Lattice Propel を起動し、`propel_ws/ice40_sm/ice40_sm.sbx` を開く  
2. RTL を編集・ビルド  
3. Radiant で `ice40_sm.rdf` を開き、FPGA に書き込み

---
## 📄 ライセンス

各ソースに書かれてあるライセンスを参照してください。

---

## 🙋‍♂️ 貢献

Issue や Pull Request は歓迎です。お気軽にどうぞ！
