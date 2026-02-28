# ══════════════════════════════════════════════════════════════════════════════
# Muon — 專案指令總覽
# 使用方式：make <target>
# ══════════════════════════════════════════════════════════════════════════════

.PHONY: help \
        run run-prod \
        build-apk build-apk-prod build-appbundle \
        build-macos build-macos-prod dmg \
        gen gen-watch \
        test lint clean \
        backend-up backend-down backend-build backend-logs backend-restart \
        backend-test

# 預設目標：顯示說明
.DEFAULT_GOAL := help

# ── 顏色定義 ──────────────────────────────────────────────────────────────────
CYAN  := \033[0;36m
RESET := \033[0m

help: ## 顯示所有可用指令
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# ══════════════════════════════════════════════════════════════════════════════
# Flutter — 開發
# ══════════════════════════════════════════════════════════════════════════════

# 預設裝置參數，若指令帶入 d=device_id 則會覆寫
DEVICE := $(if $(d),-d $(d),)

run: ## 本地開發模式執行 (可帶入 d=device_id)
	flutter run $(DEVICE) --dart-define-from-file=dart_defines/dev.env

run-prod: ## 正式環境測試執行 (可帶入 d=device_id)
	flutter run $(DEVICE) --dart-define-from-file=dart_defines/prod.env

# ══════════════════════════════════════════════════════════════════════════════
# Flutter — 建置
# ══════════════════════════════════════════════════════════════════════════════

build-apk: ## 建置 debug APK（開發用）
	flutter build apk --dart-define-from-file=dart_defines/dev.env

build-apk-prod: ## 建置 release APK（正式版）
	flutter build apk --release --dart-define-from-file=dart_defines/prod.env

build-appbundle: ## 建置 release App Bundle（上架 Google Play 用）
	flutter build appbundle --release --dart-define-from-file=dart_defines/prod.env

# ══════════════════════════════════════════════════════════════════════════════
# macOS — 建置與打包
# ══════════════════════════════════════════════════════════════════════════════

# App 版本（從 pubspec.yaml 自動讀取）
APP_VERSION := $(shell grep '^version:' pubspec.yaml | awk '{print $$2}' | cut -d'+' -f1)
APP_NAME    := Muon
DMG_NAME    := $(APP_NAME)-$(APP_VERSION).dmg
MACOS_APP   := build/macos/Build/Products/Release/$(APP_NAME).app

build-macos: ## 建置 macOS debug app
	flutter build macos --dart-define-from-file=dart_defines/dev.env

build-macos-prod: ## 建置 macOS release app（使用 prod.env）
	flutter build macos --release --dart-define-from-file=dart_defines/prod.env

dmg: build-macos-prod ## 建置 release app 並打包為 DMG
	@echo "→ 打包 $(DMG_NAME)..."
	@rm -rf /tmp/muon_dmg_staging
	@mkdir -p /tmp/muon_dmg_staging
	@cp -r "$(MACOS_APP)" /tmp/muon_dmg_staging/
	@ln -sf /Applications /tmp/muon_dmg_staging/Applications
	@hdiutil create \
		-volname "$(APP_NAME)" \
		-srcfolder /tmp/muon_dmg_staging \
		-ov \
		-format UDZO \
		"build/$(DMG_NAME)"
	@rm -rf /tmp/muon_dmg_staging
	@echo "✓ 完成：build/$(DMG_NAME)"

# ══════════════════════════════════════════════════════════════════════════════
# Flutter — 程式碼產生
# ══════════════════════════════════════════════════════════════════════════════

gen: ## 執行一次程式碼產生（drift、freezed、riverpod_generator）
	dart run build_runner build --delete-conflicting-outputs

gen-watch: ## 監聽模式：自動重新產生程式碼
	dart run build_runner watch --delete-conflicting-outputs

# ══════════════════════════════════════════════════════════════════════════════
# Flutter — 品質
# ══════════════════════════════════════════════════════════════════════════════

test: ## 執行所有 Flutter 測試
	flutter test

lint: ## 分析程式碼（flutter analyze）
	flutter analyze

clean: ## 清除所有建置快取（flutter clean + pub get）
	flutter clean
	flutter pub get

icon: ## 根據 assets/icon/app_icon.png 產生各平台圖示
	dart run flutter_launcher_icons

# ══════════════════════════════════════════════════════════════════════════════
# Backend（Docker）
# ══════════════════════════════════════════════════════════════════════════════

backend-up: ## 啟動後端容器（背景執行）
	docker compose -f backend/docker-compose.yml --env-file backend/.env up -d

backend-down: ## 停止並移除後端容器
	docker compose -f backend/docker-compose.yml down

backend-build: ## 重新 Build 後端 image 並啟動
	docker compose -f backend/docker-compose.yml --env-file backend/.env up -d --build

backend-logs: ## 即時查看後端 log
	docker compose -f backend/docker-compose.yml logs -f

backend-restart: ## 重新啟動後端容器
	docker compose -f backend/docker-compose.yml restart

backend-test: ## 在本地 venv 執行後端測試
	cd backend && python -m pytest tests/ -v
