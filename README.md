# user-dot-agents

跨 AI agent 的個人設定 dotfiles：把 **skills / hooks / settings.json / CLAUDE.md**
集中用 git 版控,再用一個跨平台的 `install.sh` 以 **symlink** 連回使用者家目錄
(`~/.agents` 與 `~/.claude`)。

> 在一台新機器上 `git clone` 後執行 `bash install.sh`,即可還原所有設定。

---

## 目錄結構(扁平 top-level)

```
user-dot-agents/
├── skills/          # 各 agent 共用的技能(每個子資料夾一個 skill)
├── hooks/           # Claude Code hook 腳本
├── settings.json    # Claude Code 使用者設定
├── CLAUDE.md        # Claude Code 全域指示
├── install.sh       # 安裝腳本(建立 symlink)
├── .gitignore
├── LICENSE
└── README.md
```

## install.sh 會建立的連結

| 連結來源 (repo)   | 連結目標 (家目錄)            |
| ----------------- | --------------------------- |
| `skills/`         | `~/.agents/skills`          |
| `skills/`         | `~/.claude/skills`          |
| `hooks/`          | `~/.claude/hooks`           |
| `settings.json`   | `~/.claude/settings.json`   |
| `CLAUDE.md`       | `~/.claude/CLAUDE.md`       |

`skills/` 會**同時**連到 `.agents` 與 `.claude` 兩處,讓兩邊的 agent 共用同一份技能。

---

## repo 與家目錄如何連動(會 / 不會)

> 核心觀念:這**不是同步/複製,而是「同一份檔案、兩個入口」**。資料只有一份,實體在
> repo 裡;家目錄那幾個項目只是 symlink(捷徑)指過去。所以不是「跟著更新」,而是它們
> **本來就是同一個東西**;改 repo 內容,家目錄即時生效,**不必重跑 `install.sh`**。

⚠️ `~/.claude` 與 `~/.agents` **資料夾本身不是 symlink**,只有下列「項目」是。

### ✅ 會即時連動(這 5 條連結的「內容」改動)

| 在 repo 做的事                       | 結果                                           |
| ------------------------------------ | ---------------------------------------------- |
| `skills/` 內新增 / 刪除 / 修改 skill | `~/.claude/skills`、`~/.agents/skills` 立即同步 |
| `hooks/` 內新增 / 修改 hook 腳本     | `~/.claude/hooks` 立即生效                      |
| 編輯 `settings.json`                 | `~/.claude/settings.json` 立即生效             |
| 編輯 `CLAUDE.md`                     | `~/.claude/CLAUDE.md` 立即生效                 |

### ❌ 不會連動

- **repo 裡那 5 條以外的檔案**:`README.md`、`install.sh`、`.gitignore`、`LICENSE`、
  `skills-lock.json`、`.agents/` — 改它們不影響家目錄。
- **在 repo 根目錄新增「新類型」設定**(例如 `keybindings.json`):不會自動出現,需先在
  `install.sh` 加一條 `link_one` 再重跑 `bash install.sh`。
- **家目錄裡未被連結的檔案**:`~/.claude/statusline.sh`、`~/.claude/.credentials.json`、
  `~/.claude/plugins/`、`~/.agents/.skill-lock.json` 等 — 與 repo 無關,獨立存在。

### 補充

- **雙向**:用 `/config` 改 `~/.claude/settings.json` 其實是在改 `repo/settings.json`
  (會變成 git 變更);`npx skills add -g` 寫進 `~/.agents/skills` = 寫進 `repo/skills`。
- **⚠️ 刪除陷阱**:`rm ~/.claude/skills` 只刪捷徑(repo 資料安全);但
  `rm -rf ~/.claude/skills/` 會**穿透捷徑刪掉 repo 真實資料**,務必小心。

---

## 使用方式

```bash
# 1. 取得 repo
git clone <your-remote-url> user-dot-agents
cd user-dot-agents

# 2. 建立 symlink 回家目錄
bash install.sh
```

macOS / Linux 直接執行即可。Windows 請見下方需求。

### Windows 需求

`install.sh` 需要在 **Git Bash / MSYS2** 中執行,並且要能建立原生 symlink,二擇一:

- 開啟 **開發人員模式**:設定 → 隱私權與安全性 → 開發人員專用 → 「開發人員模式」開啟
  (建議,開一次即可,免系統管理員權限);或
- 以 **系統管理員** 身分開啟終端機再執行。

腳本會自動設定 `MSYS=winsymlinks:nativestrict`,讓 `ln -s` 產生原生 symlink。

---

## 安全行為(備份)

執行 `install.sh` 時,對每個目標會先判斷狀態再處理:

| 目標目前狀態          | 處理方式                                            |
| --------------------- | --------------------------------------------------- |
| 已是 symlink          | 直接重新指向(不備份)                              |
| 空資料夾(殘留)      | 移除後建立 symlink                                  |
| 真實檔案 / 資料夾     | 先搬到 `目標.backup`(若已存在則加時間戳)再建 symlink |
| 不存在                | 直接建立 symlink                                    |

所以重跑 `install.sh` 是安全且可重複的(idempotent),也不會覆蓋掉原有的真實檔案。

---

## 備註

- **`.agents/` 與 `.skill-lock.json`**:這是 `npx skills` 工具產生的另一套目錄,
  本 repo 採用扁平 `skills/` 佈局,故已在 `.gitignore` 忽略。若磁碟上還有殘留可自行刪除。
- **superpowers**:原本 `~/.agents/skills/superpowers` 是指向 `~/.codex/superpowers`
  (obra/superpowers git clone)的 symlink,已從技能集合移除,未納入本 repo。
- **statusline.sh**:`settings.json` 參照 `~/.claude/statusline.sh`,該檔不在本 repo
  管理範圍,維持原樣留在 `~/.claude`。
