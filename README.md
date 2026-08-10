## Dev Env

- Set up [DMS Dev Env](https://danklinux.com/docs/dankmaterialshell/plugin-development#development-environment) first
- You'll have the directory `path/to/DankMaterialShell/quickshell/dms-plugins` ready
- ```bash
  cd path/to/DankMaterialShell/quickshell/dms-plugins
  git clone https://github.com/tttsaurus/dms-niri-toolbox.git
  ```
- ```bash
  mkdir -p ~/.config/DankMaterialShell/plugins/
  ln -s path/to/DankMaterialShell/quickshell/dms-plugins/dms-niri-toolbox/ ~/.config/DankMaterialShell/plugins/Toolbox
  ```
- ```bash
  dms restart
  ```
- Goto DMS `Settings -> Plugins` and turn on the plugin
- Goto DMS `Dank Bar -> Widgets` and add the plugin

Check plugin status:
```bash
dms ipc call plugins list
```

Reload `toolbox`:
```bash
dms ipc call plugins reload toolbox
```
OR
```bash
dms ipc call plugins reload toolbox
dms restart
```
