# conatus_fitness — Flutter 常用命令入口
#
# 用法：make <target>，或 `make help` 查看全部命令。
# 可变参数：DEVICE=<设备id>（见 `make devices`）、ENV_FILE=<凭据文件>（默认 env.json）。

ENV_FILE ?= env.json
DEVICE   ?=

# env.json 存在时注入构建期配置（密钥不入库，见 .gitignore）
DART_DEFINES := $(if $(wildcard $(ENV_FILE)),--dart-define-from-file=$(ENV_FILE),)
DEVICE_FLAG  := $(if $(DEVICE),-d $(DEVICE),)

.DEFAULT_GOAL := help

.PHONY: help deps devices doctor run run-release analyze format format-check \
        test check clean build-apk build-ios upgrade outdated

help: ## 显示可用命令
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

deps: ## 拉取依赖（原始仓库不可达时自动回退 mirror）
	@./tool/deps.sh

devices: ## 列出可用设备
	flutter devices

doctor: ## 诊断 Flutter 环境
	flutter doctor -v

run: ## 运行到默认设备（可传 DEVICE=xxx）
	flutter run $(DART_DEFINES) $(DEVICE_FLAG)

run-release: ## 以 release 模式运行
	flutter run --release $(DART_DEFINES) $(DEVICE_FLAG)

analyze: ## 静态分析
	flutter analyze

format: ## 格式化代码
	dart format .

format-check: ## 校验格式（不写入）
	dart format --output=none --set-exit-if-changed .

test: ## 运行测试
	flutter test

check: analyze test ## 提交前检查：分析 + 测试

clean: ## 清理构建产物
	flutter clean

build-apk: ## 构建 Android APK（release）
	flutter build apk --release $(DART_DEFINES)

build-ios: ## 构建 iOS（release，不签名）
	flutter build ios --release --no-codesign $(DART_DEFINES)

upgrade: ## 升级依赖到最新兼容版本
	@./tool/deps.sh upgrade

outdated: ## 查看可升级依赖
	flutter pub outdated