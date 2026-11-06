# 东八时钟

[English](README.md)

东八时钟是一个 macOS 菜单栏时钟，按东八区显示月、日、星期和 24 小时制时间，例如 `11月6日 周五 11:36`。点击可查看北京和洛杉矶的完整日期和时间，洛杉矶时间会按当地夏令时规则自动换算。

首次打开时会请求登录启动。之后可以用时钟面板里的「登录时打开」开关调整。

## 构建和安装

在 macOS 13 或更新版本上，使用包含 Swift 5.10 或更新版本的 Xcode 或 Command Line Tools 构建。

```sh
./scripts/build-app.sh
```

如果默认的 Swift 编译器与 SDK 版本不匹配，可以为本次构建指定 Xcode。

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/build-app.sh
```

生成的 `outputs/East8 Clock.app` 使用本地签名。把它复制到「应用程序」，再打开一次即可使用。

## 菜单栏设置

在 macOS 15 Sequoia 上，可以打开「系统设置 → 控制中心 → 时钟选项」，把「显示日期」设为「从不」，并关掉「显示星期」。这样东八时钟显示完整的北京时间，系统时钟只显示 Mac 本地时间。

如果 Bartender 5 把东八时钟归入隐藏区，在「Menu Bar Items」里把「东八时钟」从「Hidden menu bar items」拖到「Shown menu bar items」。
