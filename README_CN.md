# Flutter Flavorizr 中文文档

一个用于在 Flutter 项目中快速创建多环境（flavors）的工具。

[![Pub](https://img.shields.io/pub/v/flutter_flavorizr.svg)](https://pub.dev/packages/flutter_flavorizr)
![Dart CI](https://github.com/AngeloAvv/flutter_flavorizr/workflows/Dart%20CI/badge.svg)
[![Star on GitHub](https://img.shields.io/github/stars/AngeloAvv/flutter_flavorizr.svg?style=flat&logo=github&colorB=deeppink&label=stars)](https://github.com/AngeloAvv/flutter_flavorizr)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/AngeloAvv)

[English](README.md) | [中文](README_CN.md)

如果这个项目对你有帮助，欢迎点 Star、分享项目，或通过 [Github Sponsor](https://github.com/sponsors/AngeloAvv) 支持维护。

## 目录

- [快速开始](#快速开始)
- [安装](#安装)
- [鸿蒙接入指南](#鸿蒙接入指南)
- [配置你的 flavors](#配置你的-flavors)
- [字段说明](#字段说明)
- [使用方式](#使用方式)
- [运行 flavors](#运行-flavors)
- [默认处理器集合](#默认处理器集合)
- [自定义应用逻辑](#自定义应用逻辑)
- [第三方服务](#第三方服务)
- [故障排查](#故障排查)
- [许可证](#许可证)


### 前置条件

在运行 Flutter Flavorizr 前，需要安装：

- [Ruby](https://www.ruby-lang.org/en/documentation/installation/)
- [Gem](https://rubygems.org/pages/download)
- [Xcodeproj](https://github.com/CocoaPods/Xcodeproj)（通过 RubyGems 安装）

这些前置条件主要用于处理 iOS / macOS 项目配置。如果你只做 Android，可跳过。

如果你的 App 引用了 Flutter 插件，并且要生成 iOS/macos flavors，请确保 `ios/` 或 `macos/` 下已有 `Podfile`。  
否则可能触发此问题：["Unable to load contents of file list"](doc%2Ftroubleshooting%2Funable-to-load-contents-of-file-list%2FREADME.md)。

## 安装

建议在 `pubspec.yaml` 的 `dev_dependencies` 中添加：

```yaml
dev_dependencies:
  flutter_flavorizr: 
    git: https://github.com/lengain/flutter_flavorizr.git
```

安装依赖：

```terminal
flutter pub get
```

## 鸿蒙接入指南

### 1) 接入前准备

- 项目已包含 `ohos/` 工程目录
- 已在 `dev_dependencies` 中引入 `flutter_flavorizr`
- 建议先执行一次：
  - `flutter pub get`

### 2) 在配置中添加 OHOS 字段

示例：

```yaml
flavors:
  apple:
    app:
      name: "Apple App"
    ohos:
      bundleName: "com.example.apple.ohos"
      product:
        compatibleSdkVersion: "5.1.0(18)"
        runtimeOS: "HarmonyOS"
        bundleType: "app"
        signingConfig: "apple_debug"
      target:
        source:
          sourceRoots:
            - "./src/apple_files"
        resource:
          directories:
            - "./src/main/apple_debug/resources"
            - "./src/main/resources"
```

接入说明：

- product 和 target 的 `name` 字段由 flavor key（如上例中的 `apple`）自动生成，无需手动指定。这确保了与 `flutter run --flavor apple` 命令中的 flavor 名称始终一致
- `ohos.target.source/sourceRoots`、`ohos.target.resource/directories` 都是可选
- 不传 `source/resource` 时不会写默认值

### 3) 执行命令

全量执行：

```terminal
flutter pub run flutter_flavorizr
```

仅执行鸿蒙相关处理器（推荐接入初期使用）：

```terminal
flutter pub run flutter_flavorizr -p assets:download,assets:extract,ohos:products,ohos:targets,ohos:icons
```

### 4) 生成结果说明

- `ohos:products`
  - 写入 `app.products[]`
  - 自动探测以下文件（按顺序）：
    - `ohos/build-profile5.json5`
    - `ohos/build-profile.json5`
    - `build-profile5.json5`
    - `build-profile.json5`
    - 若都不存在，生成 `ohos/build-profile.generated.json5`
- `ohos:targets`
  - 写入 `targets[]`
  - 自动探测以下文件（按顺序）：
    - `ohos/entry/build-profile5.json5`
    - `ohos/entry/build-profile.json5`
    - `entry/build-profile5.json5`
    - `entry/build-profile.json5`
    - 若都不存在，生成 `ohos/entry/build-profile.generated.json5`
  - 当配置了 `sourceRoots` 时，目录不存在会自动创建
  - 当配置了 `resource.directories` 时：
    - 会跳过 `./src/main/resources`
    - 其余目录不存在会自动创建
    - 自动补齐子目录：`base/element`、`base/media`、`en_US/element`、`zh_CN/element`

### 5) 快速排查

- **没生效**：先确认 `instructions` 是否包含 `ohos:products/ohos:targets`
- **目标文件不对**：检查工程中是否存在更高优先级的 `build-profile*.json5`
- **目录未创建**：确认 `sourceRoots` / `resource.directories` 确实传值且为字符串数组

你可以在项目根目录新增 `flavorizr.yaml`，并定义 flavor。推荐方式如下：

```yaml
flavors:
  apple:
    app:
      name: "Apple App"
    android:
      applicationId: "com.example.apple"
    ios:
      bundleId: "com.example.apple"
    macos:
      bundleId: "com.example.apple"
    ohos:
      bundleName: "com.example.apple.ohos"
  banana:
    app:
      name: "Banana App"
    android:
      applicationId: "com.example.banana"
    ios:
      bundleId: "com.example.banana"
    macos:
      bundleId: "com.example.banana"
    ohos:
      bundleName: "com.example.banana.ohos"
```

详细可查看[example/flavorizr.yaml](example/flavorizr.yaml)

## 字段说明

### 顶层 `flavorizr`

| key          | type   | default | required | description               |
|:------------ |:------ |:------- |:-------- |:------------------------- |
| app          | Object |         | false    | 应用级通用配置                   |
| flavors      | Array  |         | true     | flavor 列表                 |
| instructions | Array  |         | false    | 自定义执行处理器列表                |
| assetsUrl    | String | 发布包内置地址 | false    | 资产 zip 下载地址               |
| ide          | Array  |         | false    | IDE 配置（`vscode` / `idea`） |

### 可用处理器（Instructions）

| value                   | category      | description                   |
|:----------------------- |:------------- |:----------------------------- |
| assets:download         | Miscellaneous | 下载资源包                         |
| assets:extract          | Miscellaneous | 解压资源包                         |
| assets:clean            | Miscellaneous | 清理资源                          |
| android:flavorizrGradle | Android       | 生成 flavor Gradle 片段           |
| android:buildGradle     | Android       | 注入到 build.gradle              |
| android:androidManifest | Android       | 替换 AndroidManifest 中 app 名称引用 |
| android:dummyAssets     | Android       | 生成 Android 默认占位资源             |
| android:icons           | Android       | 生成 Android 图标                 |
| flutter:flavors         | Flutter       | 生成 `flavors.dart`             |
| flutter:app             | Flutter       | 生成 `app.dart`                 |
| flutter:pages           | Flutter       | 生成页面样例                        |
| flutter:main            | Flutter       | 生成入口 main                     |
| ios:podfile             | iOS           | 更新 Pods 路径                    |
| ios:xcconfig            | iOS           | 生成 xcconfig                   |
| ios:buildTargets        | iOS           | 生成 build targets              |
| ios:schema              | iOS           | 生成 scheme                     |
| ios:dummyAssets         | iOS           | 生成 iOS 默认占位资源                 |
| ios:icons               | iOS           | 生成 iOS 图标                     |
| ios:plist               | iOS           | 更新 info.plist                 |
| ios:launchScreen        | iOS           | 生成 launch screen              |
| macos:podfile           | macOS         | 更新 Pods 路径                    |
| macos:xcconfig          | macOS         | 生成 xcconfig                   |
| macos:configs           | macOS         | 生成配置文件                        |
| macos:buildTargets      | macOS         | 生成 build targets              |
| macos:schema            | macOS         | 生成 scheme                     |
| macos:dummyAssets       | macOS         | 生成 macOS 默认占位资源               |
| macos:icons             | macOS         | 生成 macOS 图标                   |
| macos:plist             | macOS         | 更新 info.plist                 |
| ohos:products           | OHOS          | 更新鸿蒙 `app.products[]`         |
| ohos:targets            | OHOS          | 更新鸿蒙 `entry.targets[]`        |
| ohos:icons              | OHOS          | 分发鸿蒙图标                        |
| google:firebase         | Google        | 注入 Firebase 配置                |
| huawei:agconnect        | Huawei        | 注入 AGConnect 配置               |
| ide:config              | IDE           | 生成 IDE 调试配置                   |

### `app`（顶层 app）

| key                       | type       | default     | required | description                   |
|:------------------------- |:---------- |:----------- |:-------- |:----------------------------- |
| android.flavorDimensions  | String     | flavor-type | false    | Android flavorDimensions      |
| android.resValues         | Array      | {}          | false    | Android 全局 resValues          |
| android.buildConfigFields | Array      | {}          | false    | Android 全局 buildConfigFields  |
| ios.buildSettings         | Dictionary | {}          | false    | iOS 全局 XCode Build Settings   |
| macos.buildSettings       | Dictionary | {}          | false    | macOS 全局 XCode Build Settings |

### `app`（flavor 下）

| key  | type   | default | required | description |
|:---- |:------ |:------- |:-------- |:----------- |
| name | String |         | true     | 应用名称        |
| icon | String |         | false    | flavor 图标路径 |

### `android`（flavor 下）

| key                 | type   | default | required | description   |
|:------------------- |:------ |:------- |:-------- |:------------- |
| applicationId       | String |         | true     | Android 包名    |
| firebase            | Object |         | false    | Firebase 配置   |
| agconnect           | Object |         | false    | AGConnect 配置  |
| resValues           | Array  |         | false    | Android 资源值   |
| buildConfigFields   | Array  |         | false    | Android 构建常量  |
| customConfig        | Array  |         | false    | 自定义 Gradle 字段 |
| generateDummyAssets | bool   | true    | false    | 是否生成占位资源      |
| icon                | String |         | false    | Android 图标路径  |
| adaptiveIcon        | Array  |         | false    | Android 自适应图标 |

### `ios` / `macos`（flavor 下）

| key                 | type       | default | required | description                   |
|:------------------- |:---------- |:------- |:-------- |:----------------------------- |
| bundleId            | String     |         | true     | Bundle ID                     |
| buildSettings       | Dictionary | {}      | false    | Flavor 级 XCode Build Settings |
| firebase            | Object     |         | false    | Firebase 配置                   |
| variables           | Array      |         | false    | 变量配置                          |
| generateDummyAssets | bool       | true    | false    | 是否生成占位资源                      |
| icon                | String     |         | false    | 图标路径                          |

### `ohos`（flavor 下）

| key                 | type   | default | required | description                                             |
|:------------------- |:------ |:------- |:-------- |:------------------------------------------------------- |
| bundleName          | String |         | false    | OHOS 应用包名（Bundle Name）                                  |
| product             | Object | {}      | false    | 映射到 `app.products[]` 的配置                                |
| target              | Object |         | false    | 映射到 `entry.targets[]` 的配置；未配置时不生成 `source/resource` 默认值 |
| resValues           | Array  | {}      | false    | 资源值配置                                                   |
| buildConfigFields   | Array  | {}      | false    | 构建常量                                                    |
| generateDummyAssets | bool   | true    | false    | 是否生成占位资源                                                |
| icon                | String |         | false    | OHOS 图标路径                                               |

> **关于 product/target 命名**：生成的 `product.name` 和 `target.name` 始终取 flavor key（如 `apple`、`banana`），与 `flutter run --flavor` 传入的名称自动保持一致，无需手动指定。

### `product`（仅 OHOS）

| key                  | type   | default               | required | description         |
|:-------------------- |:------ |:--------------------- |:-------- |:------------------- |
| compatibleSdkVersion | String | 6.0.2(22)             | false    | 兼容 SDK 版本           |
| targetSdkVersion     | String |                       | false    | 目标 SDK 版本（仅显式配置时输出） |
| runtimeOS            | String | HarmonyOS             | false    | 运行时系统               |
| bundleName           | String |                       | false    | 包名（仅显式配置时输出）        |
| bundleType           | String |                       | false    | 包类型（仅显式配置时输出）       |
| icon                 | String |                       | false    | 产品图标资源（仅显式配置时输出）    |
| label                | String |                       | false    | 产品名称资源（仅显式配置时输出）    |
| signingConfig        | String | normalize(flavor key) | false    | 签名配置名（自动去除非字母数字字符）  |

## 使用方式

配置完成后执行：

```terminal
flutter pub run flutter_flavorizr
```

### 仅执行部分处理器

```terminal
flutter pub run flutter_flavorizr -p <processor_1>,<processor_2>
```

例如：

```terminal
flutter pub run flutter_flavorizr -p assets:download
flutter pub run flutter_flavorizr -p assets:download,assets:extract
flutter pub run flutter_flavorizr -p assets:download,assets:extract,ohos:products,ohos:targets
```

处理器顺序很重要。经验上请先执行 `assets:download` + `assets:extract`，再执行平台处理器。

### 详细日志与无确认模式

```terminal
flutter pub run flutter_flavorizr -v
flutter pub run flutter_flavorizr -f
```

## 运行 flavors

```terminal
flutter run --flavor <flavorName>
```

示例：

```terminal
flutter run --flavor apple
flutter run --flavor banana
```

当前 Flutter SDK 的已知问题会影响终端直接运行 macOS flavors，通常需在 XCode 里选择 scheme 运行。

### 鸿蒙平台运行

鸿蒙平台运行前需要先完成 OHOS 工程的依赖安装和同步。以 `apple` flavor 为例：

```bash
# 1. 获取工具目录（$TOOL_HOME 为 DevEco Studio 安装路径）
echo $TOOL_HOME

# 2. 进入 ohos 目录，安装 ohpm 依赖
cd ohos
$TOOL_HOME/tools/ohpm/bin/ohpm install --all --registry https://ohpm.openharmony.cn/ohpm/ --strict_ssl true

# 3. 同步工程（product 名称即 flavor key）
$TOOL_HOME/tools/node/bin/node $TOOL_HOME/tools/hvigor/bin/hvigorw.js \
  --sync -p product=apple -p buildMode=debug \
  --analyze=normal --parallel --incremental --daemon

# 4. 回到项目根目录运行
cd ..
flutter run --flavor apple -d <device_id>
```

> `flutter run --flavor apple` 会自动在 `build-profile.json5` 中匹配 `name: 'apple'` 的 product 进行构建。这也是 product name 必须与 flavor key 一致的原因。

## 默认处理器集合

默认会按以下顺序执行（未指定 `-p` 时）：

- assets:download
- assets:extract
- android:androidManifest
- android:flavorizrGradle
- android:buildGradle
- android:dummyAssets
- android:icons
- flutter:flavors
- flutter:app
- flutter:pages
- flutter:main
- ios:podfile
- ios:xcconfig
- ios:buildTargets
- ios:schema
- ios:dummyAssets
- ios:icons
- ios:plist
- ios:launchScreen
- macos:podfile
- macos:xcconfig
- macos:configs
- macos:buildTargets
- macos:schema
- macos:dummyAssets
- macos:icons
- macos:plist
- ohos:products
- ohos:targets
- ohos:icons
- google:firebase
- huawei:agconnect
- assets:clean
- ide:config

关于 `ohos:products` 与 `ohos:targets` 的设计原则：

- 与 HarmonyOS 多产品/多目标官方模式保持一致
- 合并已有配置时，尽量保留非 flavorizr 管理内容
- 同名条目按 flavor 配置覆盖，确保可重复执行

参考：

- https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-customized-multi-targets-and-products-guides
- https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-customized-multi-targets-and-products-sample
- https://gitcode.com/HarmonyOS_Samples/MultiTarget.git

## 自定义应用逻辑

Flavorizr 会在 `lib/` 下生成多个 Dart 文件。  
其中 `flavors.dart` 里会有 `F` 类，可根据当前 flavor 提供差异化配置：

```dart
class F {
  static late final Flavor appFlavor;

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.apple:
        return 'Apple App';
      case Flavor.banana:
        return 'Banana App';
    }
  }
}
```

你可以在这里扩展主题色、接口地址、实验开关等业务配置。

## 第三方服务

### Google Firebase

在对应平台 flavor 下配置 `firebase.config`：

```yaml
flavors:
  apple:
    android:
      applicationId: "com.example.apple"
      firebase:
        config: ".firebase/apple/google-services.json"
    ios:
      bundleId: "com.example.apple"
      firebase:
        config: ".firebase/apple/GoogleService-Info.plist"
```

Flavorizr 只负责配置注入，不负责替你添加原生依赖。  
建议结合 [flutterfire_cli](https://firebase.google.com/docs/flutter/setup) 使用。

### Huawei AppGallery Connect

当前代码仅支持在 **Android flavor** 下配置 `agconnect.config`：

```yaml
flavors:
  apple:
    android:
      applicationId: "com.example.apple"
      agconnect:
        config: ".agconnect/apple/agconnect-services.json"
```

## 故障排查

["Unable to load contents of file list" 问题说明](doc%2Ftroubleshooting%2Funable-to-load-contents-of-file-list%2FREADME.md)

## 社区教程

- [Easily build flavors in Flutter (Android and iOS) with flutter_flavorizr](https://angeloavv.medium.com/easily-build-flavors-in-flutter-android-and-ios-with-flutter-flavorizr-d48cbf956e4) - Angelo Cassano
- [Get the best out of Flutter flavors with flutter_flavorizr](https://pierre-dev.hashnode.dev/get-the-best-out-of-flutter-flavors-with-flutterflavorizr) - Pierre Monier

## 后续计划

- 支持用户定义可用处理器集合

## 问题与反馈

使用中遇到问题欢迎提 issue。  
如果是使用咨询或功能建议，建议使用项目 Discussions。

## 许可证

Flutter Flavorizr 使用 MIT 协议，详见 `LICENSE`。
