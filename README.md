> [!IMPORTANT]
> **Project Archived**
>
> LcInstaller is no longer actively maintained.
>
> This project was originally created after the mass revoke of developer certificates, when LiveContainer did not support repository based installs. LcInstaller provided a simple way to add repos and install apps directly into LiveContainer without manually downloading IPA files.
>
> LiveContainer now includes built in repository support, which makes LcInstaller largely unnecessary. Because of this, the project has been archived and will not receive further updates.
>
> Thank you to everyone who used and supported this project.
> 
# LcInstaller

LcInstaller is a **Flutter app** that makes installing apps into [LiveContainer](https://github.com/LiveContainer/LiveContainer) effortless.

Instead of manually searching for `.ipa` files, downloading them, and then importing into LiveContainer, you can simply add **repos** (just like in ESign, Feather, etc.) and install apps directly.

---

## ✨ Features

* 📂 Add and manage repos that host `.ipa` apps.
* ⚡ One-click install into LiveContainer using its URL scheme.
* 🔄 Easily update or switch apps without tedious manual steps.
* 🎨 UI design inspired by [Feather](https://github.com/khcrysalis/Feather).

---

## 🛠 Motivation

I built this app because I love testing and updating different apps, but the **manual process** (search → download → import) was a pain.

I originally used **Feather**, but after the revoke wave of certificates, I switched fully to **LiveContainer**. LcInstaller brings the simplicity of repo-based installs to LiveContainer.

---

## ⚙️ How It Works

LcInstaller uses LiveContainer’s custom URL scheme:

```
livecontainer://install?url=https://example.com/app.ipa
```

When you tap install inside LcInstaller, it tells LiveContainer to fetch the `.ipa` directly and handle the installation.

✅ You don’t need to manage files, downloads, or imports yourself.

---

## 📌 Important Notes

* If you install **LcInstaller inside LiveContainer itself**, you must:

  * Run it in **LiveContainer2**, **or**
  * Run it in **multi-tasking mode**.

This ensures the main LiveContainer instance remains free to handle the actual install process.

* Distribution through the App Store is not possible (it won’t pass Apple review). You’ll need to sideload the app.

---

## 📥 Installation

1. Go to the [Releases](https://github.com/asrma7/LiveContainer-Installer/releases) page.
2. Download the latest `.ipa` file.
3. Install it via:

   * **AltStore / SideStore / TrollStore**, or
   * **LiveContainer** (just import the IPA directly).

---

## ❤️ Credits

* Inspired by [Feather](https://github.com/khcrysalis/Feather) app design.
* Built with **Flutter**.

---

## 📄 License

MIT License – feel free to fork, improve, and contribute!
