❯ nix run . -- switch --flake . -b backup
Starting Home Manager activation
Activating checkFilesChanged
Activating checkLinkTargets
Existing file '/home/harry/.config/fastfetch/config.jsonc' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/fastfetch/config.jsonc', will be moved to '/home/harry/.config/fastfetch/config.jsonc.backup'
Existing file '/home/harry/.config/fastfetch/logos/snorlax.txt' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/fastfetch/logos/snorlax.txt', will be skipped since they are the same
Existing file '/home/harry/.config/fastfetch/logos/pikachu.txt' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/fastfetch/logos/pikachu.txt', will be skipped since they are the same
Existing file '/home/harry/.config/fastfetch/logos/magikarp.txt' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/fastfetch/logos/magikarp.txt', will be skipped since they are the same
Existing file '/home/harry/.config/fastfetch/logos/charmander.png' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/fastfetch/logos/charmander.png', will be skipped since they are the same
Existing file '/home/harry/.config/fastfetch/logos/snorlax.png' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/fastfetch/logos/snorlax.png', will be skipped since they are the same
Existing file '/home/harry/.config/fastfetch/config-minimal.jsonc' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/fastfetch/config-minimal.jsonc', will be moved to '/home/harry/.config/fastfetch/config-minimal.jsonc.backup'
Existing file '/home/harry/.config/nvim/lua/completion.lua' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/nvim/lua/completion.lua', will be moved to '/home/harry/.config/nvim/lua/completion.lua.backup'
Existing file '/home/harry/.config/nvim/lua/options.lua' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/nvim/lua/options.lua', will be moved to '/home/harry/.config/nvim/lua/options.lua.backup'
Existing file '/home/harry/.config/nvim/lua/lsp.lua' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/nvim/lua/lsp.lua', will be moved to '/home/harry/.config/nvim/lua/lsp.lua.backup'
Existing file '/home/harry/.config/nvim/lua/keymaps.lua' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/nvim/lua/keymaps.lua', will be moved to '/home/harry/.config/nvim/lua/keymaps.lua.backup'
Existing file '/home/harry/.config/nvim/lua/plugins.lua' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/nvim/lua/plugins.lua', will be moved to '/home/harry/.config/nvim/lua/plugins.lua.backup'
Existing file '/home/harry/.config/nvim/lua/cp.lua' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/nvim/lua/cp.lua', will be moved to '/home/harry/.config/nvim/lua/cp.lua.backup'
Existing file '/home/harry/.config/nvim/init.lua' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.config/nvim/init.lua', will be moved to '/home/harry/.config/nvim/init.lua.backup'
Existing file '/home/harry/.zshrc' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.zshrc', will be moved to '/home/harry/.zshrc.backup'
Existing file '/home/harry/.zprofile' is in the way of '/nix/store/6lr8p9z5g4f2hm83fy3da768msayllyj-home-manager-files/.zprofile', will be moved to '/home/harry/.zprofile.backup'
Please do one of the following:
- In standalone mode, use 'home-manager switch -b backup' to back up files automatically.
- When used as a NixOS or nix-darwin module, set either
  - 'home-manager.backupFileExtension', or
  - 'home-manager.backupCommand',
  to move the file to a new location in the same directory, or run a custom command.
- Set 'force = true' on the related file options to forcefully overwrite the files below. eg. 'xdg.configFile."mimeapps.list".force = true'
Existing file '/home/harry/.config/starship.toml.backup' would be clobbered by backing up '/home/harry/.config/starship.toml'

