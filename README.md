# East8 Clock

[简体中文](README.zh-CN.md)

East8 Clock shows the month, day, weekday, and 24-hour time in UTC+8 in the macOS menu bar, for example `11月6日 周五 11:36`. Click it to see the full date and time in Beijing and Los Angeles. Los Angeles time adjusts for daylight saving automatically.

The app requests launch at login the first time it opens. Use the **登录时打开** (Open at Login) switch in the clock panel to change this.

## Build and install

Build on macOS 13 or later with Xcode or Command Line Tools that include Swift 5.10 or later.

```sh
./scripts/build-app.sh
```

If the default Swift compiler and SDK versions do not match, select Xcode for this build.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/build-app.sh
```

Copy the locally signed `outputs/East8 Clock.app` to Applications and open it once.

## Menu bar setup

On macOS 15 Sequoia, go to **System Settings → Control Center → Clock Options**. Set **Show date** to **Never** and turn off **Show the day of the week** to keep the built-in clock compact. You can then read the full Beijing date and time from East8 Clock and your Mac's local time from the built-in clock.

If Bartender 5 hides East8 Clock, move **东八时钟** from **Hidden menu bar items** to **Shown menu bar items** in **Menu Bar Items**.
