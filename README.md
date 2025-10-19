# SChat Tweak (iOS)

![screenshot](https://adriancastro.dev/c6wkhfl0rq1f.PNG)

Tweak to inject [SChat](https://github.com/Soncresity-Industries/SChat-iOS) and [OpenInDiscord](https://github.com/Soncresity-Industries/OpenInDiscord) into Discord. Forked from 
[BunnyTweak](https://github.com/pyoncord/BunnyTweak) which is forked from [VendettaTweak](https://github.com/vendetta-mod/VendettaTweak) and modified to match with [SChat-Xposed](https://github.com/Soncresity-Industries/SChat-Xposed)'s behavior.

> [!WARNING]
> When sideloading with an ADP account cert, some functionality will break. If you value these features, sideload with a local development certificate instead. There is a workaround available that fixes one of the issues. See below for details.

<details>
<summary>Issues & Workaround</summary>
<br/>
To resolve the fixable issue, you need to match the app's bundle ID with your provisioning profile's App ID (excluding the team ID prefix):
<table>
<tr>
    <th>Issue</th>
    <th>Fixable</th>
    <th>Example</th>
</tr>
<tr>
    <td>Cannot change app icons</td>
    <td>✓</td>
    <td rowspan="5"><img src="https://adriancastro.dev/e0hbonxknepw.jpg" width="300"></td>
</tr>
<tr>
    <td>Cannot share items to Discord</td>
    <td>✗</td>
</tr>
<tr>
    <td>Cannot use passkeys</td>
    <td>✗</td>
</tr>
</table>

## Doing this will break notifications if the app is backgrounded or closed

</details>

## Installation

Builds can be found in the [Releases](https://github.com/Soncresity-Industries/SChat-Tweak/releases/latest) tab.

### Jailbroken

> [!IMPORTANT]
> There currently isn't a repo for Jailbroken devices to install SChat.
> For now please use the method below

- Manually install by downloading the Debian package (or by building your own, see [Building](#building)) and adding it to your package manager

### Jailed

<a href="https://tinyurl.com/bdfkbtf7"><img src="https://adriancastro.dev/0byxzkzdsauj.png" width="230"></a>
<a href="https://tinyurl.com/24zjszuf"><img src="https://i.imgur.com/dsbDLK9.png" width="230"></a>
<a href="https://tinyurl.com/yh455zk6"><img src="https://i.imgur.com/46qhEAv.png" width="230"></a>

> [!NOTE]
> TrollStore may display an encryption warning, which you can disregard.

- Download and install [SChat.ipa](https://github.com/Soncresity-Industries/SChat-Tweak/releases/latest/download/SChat.ipa) using your preferred sideloading method.

## Building

<details>
<summary>Instructions</summary>

> These steps assume you use macOS.

1. Install Xcode from the App Store. If you've previously installed the `Command Line Utilities` package, you will need to run `sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer` to make sure you're using the Xcode tools instead.

> If you want to revert the `xcode-select` change, run `sudo xcode-select -switch /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk`

2. Install the required dependencies. You can do this by running `brew install make ldid` in your terminal. If you do not have brew installed, follow the instructions [here](https://brew.sh/).

3. Setup your gnu make path:

```bash
export PATH="$(brew --prefix make)/libexec/gnubin:$PATH"
```

4. Setup [theos](https://theos.dev/docs/installation-macos) by running the script provided by theos.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
```

If you've already installed theos, you can run `$THEOS/bin/update-theos` to make sure it's up to date.

5. Clone this repository via `git clone git@github.com:Soncresity-Industries/SChat-Tweak.git` and `cd` into it.

6. To build, you can run `make package`.

The resulting `.deb` file will be in the `packages` folder.

</details>

## Contributors

[![Contributors](https://contrib.rocks/image?repo=Soncresity-Industries/SChat-Tweak)](https://github.com/Soncresity-Industries/SChat-Tweak/graphs/contributors)

## Important Clarification Regarding Licensing

This project was originally licensed under the **Open Software License 3.0 (OSL 3.0)**.

An amendment attempting to add a "Substantial Changes Requirement" was introduced in commit `b7cd1471f7d9dd79fe7832e7e7face296f2fd6a6`. This amendment claimed retroactive effect starting from commit `c568969333ae20bbbb6e924f6404e4f02fb65fd7`, subsequent to significant code revisions.

As the repository owner, and in the interest of clarity upon archiving this project, please note the following:

- Applying license changes retroactively is generally invalid. All code committed and distributed *before* the amendment was actually introduced in `b7cd147` was under the standard OSL 3.0 terms applicable at that time.
- The attempt to make this amendment effective retroactively (from commit `c568969`, before it was introduced in `b7cd147`) is procedurally invalid. Additionally, the Open Software License 3.0, like most standard open-source licenses, is intended to be used without modification to its own terms. Creating custom amendments *to the OSL 3.0 text itself* raises significant questions about the resulting license's validity and enforceability.
- Given the procedural issues, particularly the invalid retroactive application, the repository owner considers the amendment non-binding. The **entire codebase within this repository, reflecting its state upon archival, is intended to remain governed by the standard, unmodified Open Software License 3.0**, as contained in the `LICENSE` file prior to commit `b7cd147`. Versions of the code prior to commit `b7cd147` are unequivocally available under the standard OSL 3.0.
- This means **you may freely fork, modify, and redistribute this codebase in accordance with the OSL 3.0** without needing to meet arbitrary "substantial modification" thresholds.

To reflect this, the `LICENSE` file has been restored to contain only the original OSL 3.0 text prior to archiving.
