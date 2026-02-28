# ══════════════════════════════════════════════════════════════════════════════
# Muon — 專案指令總覽
# 使用方式：make <target>
# ══════════════════════════════════════════════════════════════════════════════

.PHONY: help \
        run run-prod \
        build-apk build-apk-prod build-appbundle \
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
