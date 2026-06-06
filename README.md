# user-dot-agents

![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue)
![Shell](https://img.shields.io/badge/install-bash%20%7C%20PowerShell-green)
![Method](https://img.shields.io/badge/method-symlink-orange)
![Idempotent](https://img.shields.io/badge/idempotent-yes-success)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

跨 AI agent 的個人設定 dotfiles:把 **skills / hooks / settings.json / CLAUDE.md**
集中用 git 版控,再用跨平台安裝腳本以 **symlink** 連回使用者家目錄
(`~/.agents` 與 `~/.claude`)。

> 在一台新機器上 `git clone` 後執行安裝腳本,即可一次還原所有設定。

---

## 為什麼需要這個 Repo

AI agent 的設定散落在家目錄各處(`~/.claude`、`~/.agents`…),換機器、重灌或多台同步時很難管理。
這個 repo 把它們**集中成單一來源**用 git 版控;安裝腳本只建立 symlink,所以家目錄看到的
就是 repo 裡的同一份檔案——**改一處、處處生效**,還能用 git 追歷史、回溯、跨機還原。

## ✨ 特色

- **集中版控**:skills / hooks / settings.json / CLAUDE.md 全收進一個 repo。
- **Symlink 單一來源**:家目錄是捷徑指回 repo,不是複製,沒有「兩份不同步」問題。
- **冪等 + 自動備份**:重跑安裝腳本安全可重複;遇到既有實體檔會先備份再連結。
- **跨平台**:macOS / Linux(`install.sh`)與原生 Windows PowerShell(`install.ps1`)。
- **內建安全網**:`hooks/block-dangerous-bash.sh` 在執行前攔截危險指令。

---

## 📦 內容物

### Skills(共 19 個,依用途分類)

| 分類 | Skills | 用途 |
| ---- | ------ | ---- |
| 🎨 設計 | `frontend-design` | 前端 UI 設計與美化 |
| 🧠 規劃 / 需求 | `grill-me`、`grill-with-docs`、`to-prd`、`to-issues`、`triage`、`zoom-out` | 拷問計畫、寫 PRD、拆 issue、分流、拉高視角 |
| 🛠 開發 / 測試 | `tdd`、`diagnose`、`prototype`、`improve-codebase-architecture` | TDD、除錯、原型、架構改善 |
| 🧩 Skill 管理 | `find-skills`、`write-a-skill`、`setup-matt-pocock-skills` | 尋找 / 撰寫 / 安裝 skill |
| ⚡ 工作流輔助 | `caveman`、`commit-message-writer`、`handoff`、`sequential-thinking` | 精簡輸出、commit 訊息、交接、結構化思考 |
| ☁️ 大型套件 | `microsoft-foundry` | Azure AI Foundry 全套(模型部署、fine-tuning、agent) |

### Hooks — `block-dangerous-bash.sh`

Claude Code 的 **PreToolUse 安全 hook**(在 `settings.json` 的 `permissions.deny` 之外再加一層防護)。
它檢查**完整的 Bash 指令字串**,不管旗標順序如何都能攔截破壞性操作,命中即 `deny`:

- `rm` 帶 `-r` / `-R` / `-f`(遞迴 / 強制)
- `sudo`
- `dd`、`mkfs`、`diskutil erase`
- `chmod 777`
- `git reset --hard`、`git push --force`/`-f`、`git clean -f`、`git branch -D`
- `shutdown`、`reboot`
- `truncate`、`: >`(清空檔案)

### settings.json

Claude Code 使用者設定:`model: opus`、`permissions.deny`(上面那些危險指令)、
`PreToolUse` hook 接線(Bash → `block-dangerous-bash.sh`)、`statusLine`、
以及 `attribution` 留空(**commit 不含 Claude 署名**)。

### CLAUDE.md

全域行為準則(Think Before Coding / Simplicity First / Surgical Changes / Goal-Driven Execution)。

---

## 🚀 快速開始

```bash
# 1. 取得 repo
git clone <your-remote-url> user-dot-agents
cd user-dot-agents
```

### 2. 建立 symlink 回家目錄

**Windows —(A)原生 PowerShell(建議)**

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

腳本會自動偵測「開發人員模式 / 系統管理員」。若兩者皆無,會跳出 **UAC** 以系統管理員身分重跑;
或加 `-NoElevate` 改為開啟「開發人員模式」設定頁,讓你手動開啟後再執行。

**Windows —(B)Git Bash / MSYS2**

```bash
bash install.sh
```

需先開啟開發人員模式或以系統管理員執行;腳本會自動設定 `MSYS=winsymlinks:nativestrict`
讓 `ln -s` 產生原生 symlink。

**macOS / Linux**

```bash
bash install.sh
```

---

## 🔗 連結對應表

| 連結來源 (repo)   | 連結目標 (家目錄)            |
| ----------------- | --------------------------- |
| `skills/`         | `~/.agents/skills`          |
| `skills/`         | `~/.claude/skills`          |
| `hooks/`          | `~/.claude/hooks`           |
| `settings.json`   | `~/.claude/settings.json`   |
| `CLAUDE.md`       | `~/.claude/CLAUDE.md`       |

`skills/` 會**同時**連到 `.agents` 與 `.claude` 兩處,讓兩邊的 agent 共用同一份技能。

---

## 🔄 repo 與家目錄如何連動(會 / 不會)

> 核心觀念:這**不是同步/複製,而是「同一份檔案、兩個入口」**。資料只有一份,實體在
> repo 裡;家目錄那幾個項目只是 symlink(捷徑)指過去。所以不是「跟著更新」,而是它們
> **本來就是同一個東西**;改 repo 內容,家目錄即時生效,**不必重跑安裝腳本**。

⚠️ `~/.claude` 與 `~/.agents` **資料夾本身不是 symlink**,只有下列「項目」是。

### ✅ 會即時連動(這 5 條連結的「內容」改動)

| 在 repo 做的事                       | 結果                                           |
| ------------------------------------ | ---------------------------------------------- |
| `skills/` 內新增 / 刪除 / 修改 skill | `~/.claude/skills`、`~/.agents/skills` 立即同步 |
| `hooks/` 內新增 / 修改 hook 腳本     | `~/.claude/hooks` 立即生效                      |
| 編輯 `settings.json`                 | `~/.claude/settings.json` 立即生效             |
| 編輯 `CLAUDE.md`                     | `~/.claude/CLAUDE.md` 立即生效                 |

### ❌ 不會連動

- **repo 裡那 5 條以外的檔案**:`README.md`、`install.sh`、`install.ps1`、`.gitignore`、
  `LICENSE`、`skills-lock.json`、`.agents/` — 改它們不影響家目錄。
- **在 repo 根目錄新增「新類型」設定**(例如 `keybindings.json`):不會自動出現,需先在
  安裝腳本加一條連結再重跑。
- **家目錄裡未被連結的檔案**:`~/.claude/statusline.sh`、`~/.claude/settings.local.json`、
  `~/.claude/.credentials.json`、`~/.claude/plugins/` 等 — 與 repo 無關,獨立存在。

### 補充

- **雙向**:用 `/config` 改 `~/.claude/settings.json` 其實是在改 `repo/settings.json`
  (會變成 git 變更);`npx skills add -g` 寫進 `~/.agents/skills` = 寫進 `repo/skills`。
- **⚠️ 刪除陷阱**:`rm ~/.claude/skills` 只刪捷徑(repo 資料安全);但
  `rm -rf ~/.claude/skills/` 會**穿透捷徑刪掉 repo 真實資料**,務必小心。

---

## 🛡 安全行為(備份)

執行安裝腳本時,對每個目標會先判斷狀態再處理:

| 目標目前狀態          | 處理方式                                            |
| --------------------- | --------------------------------------------------- |
| 已是 symlink          | 直接重新指向(不備份)                              |
| 空資料夾(殘留)      | 移除後建立 symlink                                  |
| 真實檔案 / 資料夾     | 先搬到 `目標.backup`(若已存在則加時間戳)再建 symlink |
| 不存在                | 直接建立 symlink                                    |

所以重跑安裝腳本是安全且可重複的(idempotent),也不會覆蓋掉原有的真實檔案。

---

## 📝 注意事項

- **`settings.local.json`**:Claude Code 會把「本機專屬」覆寫寫到
  `~/.claude/settings.local.json`,屬個別機器設定,**不應納入版控**(已在 `.gitignore` 忽略)。
- **`.agents/` 與 `skills-lock.json`**:`npx skills` 工具產生的另一套結構,本 repo 採用扁平
  `skills/` 佈局,故已在 `.gitignore` 忽略。若磁碟上還有殘留可自行刪除。
- **`statusline.sh`**:`settings.json` 參照 `~/.claude/statusline.sh`,該檔不在本 repo
  管理範圍,維持原樣留在 `~/.claude`。

---

## 🗂 目錄結構(扁平 top-level)

```
user-dot-agents/
├── skills/          # 19 個共用技能(每個子資料夾一個 skill)
├── hooks/           # Claude Code 安全 hook
│   └── block-dangerous-bash.sh
├── settings.json    # Claude Code 使用者設定
├── CLAUDE.md        # 全域行為準則
├── install.sh       # 安裝腳本(macOS / Linux / Git Bash)
├── install.ps1      # 安裝腳本(原生 Windows PowerShell)
├── .gitignore
├── LICENSE
└── README.md
```

---

## 📄 License

MIT — 詳見 [LICENSE](LICENSE)。
