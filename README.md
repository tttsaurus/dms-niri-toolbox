## Dev Env

- Set up [DMS Dev Env](https://danklinux.com/docs/dankmaterialshell/plugin-development#development-environment) first
  <br>**TLDR**<br>
  ```bash
  mkdir -p ~/repos && cd ~/repos
  git clone --recurse-submodules https://github.com/AvengeMedia/DankMaterialShell.git
  cd DankMaterialShell/quickshell

  # Generate QML language server config
  touch .qmlls.ini
  qs -p .  # Press Ctrl+C after it starts

  # Create your plugins here
  mkdir -p dms-plugins
  ```
- You'll have the directory `path/to/DankMaterialShell/quickshell/dms-plugins` ready
- Clone `dms-niri-toolbox`
  ```bash
  cd path/to/DankMaterialShell/quickshell/dms-plugins
  git clone https://github.com/tttsaurus/dms-niri-toolbox.git
  ```
- Symlink `dms-niri-toolbox` to the DMS plugins directory for live testing
  ```bash
  mkdir -p ~/.config/DankMaterialShell/plugins/
  ln -s path/to/DankMaterialShell/quickshell/dms-plugins/dms-niri-toolbox/ ~/.config/DankMaterialShell/plugins/Toolbox
  ```
- Goto `dms-niri-toolbox` dev env directory
  ```bash
  cd path/to/DankMaterialShell/quickshell/dms-plugins/dms-niri-toolbox/
  ```
- Force compile shaders once
  ```
  ./dev_scripts/build_shaders.sh --force
  ```
- Restart DMS
  ```bash
  dms restart
  ```
- Goto DMS `Settings -> Plugins` and turn on the plugin
- Goto DMS `Dank Bar -> Widgets` and add the plugin

**Tips**:

- Check the plugin status:
  ```bash
  dms ipc call plugins list
  ```
- Reload `toolbox`:
  ```bash
  dms ipc call plugins reload toolbox
  ```
  OR (You'll need to restart DMS most of the time)
  ```bash
  dms restart
  dms ipc call plugins reload toolbox
  ```
- Inspect the errors:
  ```bash
  journalctl --user -u dms -f
  ```
  And then run `reload`
- Compile shaders:
  ```bash
  ./dev_scripts/build_shaders.sh 
  # OR
  ./dev_scripts/build_shaders.sh --force
  ```
- Check persistent settings:
  ```bash
  jq '.toolbox' ~/.config/DankMaterialShell/plugin_settings.json
  ```
- Delete persistent settings:
  ```bash
  tmp=$(mktemp) &&
  jq 'del(.toolbox)' ~/.config/DankMaterialShell/plugin_settings.json > "$tmp" &&
  mv "$tmp" ~/.config/DankMaterialShell/plugin_settings.json
  ```
  Run `dms restart` to regenerate settings
