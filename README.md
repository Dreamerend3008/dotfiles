# 🏠 Harry's Dotfiles - Multi-Sistema

> Configuración declarativa que funciona en **NixOS**, **Ubuntu** y **WSL**

## 🎯 ¿Qué hace especial esta configuración?

Esta configuración usa **Nix Flakes** y **Home Manager** de forma inteligente:

- 🖥️  **En NixOS**: Home Manager se integra con la configuración del sistema
- 🐧 **En Ubuntu/WSL**: Home Manager funciona standalone (como siempre)
- 📦 **Mismo código**: Compartes el 99% de la configuración entre sistemas

## 📂 Estructura

```
~/dotfiles/
├── flake.nix              # Define las configuraciones para cada sistema
├── configuration.nix      # Configuración de sistema NixOS (solo NixOS)
├── home.nix              # Configuración de usuario (todos los sistemas)
├── README.md
└── config/
    ├── nvim/
    ├── starship.toml
    └── fastfetch/
```

## 🚀 Instalación

### 📦 Paso 1: Instalar Nix

#### En Ubuntu o WSL:
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
# Para WSL: sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

#### En NixOS:
Ya viene instalado! ✅

### ⚙️  Paso 2: Habilitar Flakes

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

**Reinicia tu terminal** después de este paso.

### 📥 Paso 3: Clonar dotfiles

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles ~/dotfiles
cd ~/dotfiles
```

### 🔧 Paso 4: Configurar según tu sistema

#### ⚠️ **IMPORTANTE**: Edita estos archivos primero

1. **En `flake.nix`**: Cambia `"harry"` por tu username
2. **En `home.nix`**: Cambia `home.username` y `home.homeDirectory`
3. **En `configuration.nix`** (solo NixOS): Cambia el hostname y usuario

### 🎮 Paso 5: Aplicar configuración

#### **En Ubuntu o WSL:**
```bash
# Primera vez
nix run . -- switch --flake . -b backup

# Setear Zsh como shell por defecto
echo "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
chsh -s "$HOME/.nix-profile/bin/zsh"

# Reinicia terminal
exec zsh
```

#### **En NixOS:**

Primero, copia la configuración de hardware:
```bash
# Si tienes /etc/nixos/hardware-configuration.nix
cp /etc/nixos/hardware-configuration.nix ~/dotfiles/

# Si no existe, genera una:
sudo nixos-generate-config --show-hardware-config > ~/dotfiles/hardware-configuration.nix
```

Luego aplica:
```bash
# Primera vez (todo el sistema + home)
sudo nixos-rebuild switch --flake ~/dotfiles

# Las siguientes veces usa el alias:
update
```

**Nota**: En NixOS, Zsh ya queda como shell por defecto automáticamente.

### 🧠 Neovim: requisitos (externos a Nix)

Los binarios que usa `config/nvim` (LSP/formatters/compilador) se manejan **a nivel sistema** (apt/pacman/dnf/etc.) o con herramientas como mise/asdf.

Mínimo para C++ (fix de `iostream` y `<bits/stdc++.h>`):
- `g++` (headers de libstdc++)
- `clangd`

Verifica que Neovim los ve en `PATH`:
```bash
command -v g++
command -v clangd
```
(En Neovim: `:echo exepath('g++')` y `:echo exepath('clangd')`)

Ejemplo en Ubuntu/WSL:
```bash
sudo apt update
sudo apt install -y g++ clangd clang-format
```

#### Usar estos dotfiles **sin Nix** (symlinks)
Si Nix te está dando problemas y quieres manejar Neovim “system-wise”, puedes linkear los configs:
```bash
mkdir -p ~/.config
ln -snf ~/dotfiles/config/nvim ~/.config/nvim
ln -snf ~/dotfiles/config/clangd ~/.config/clangd
```
Luego en Neovim:
- `:Lazy sync`
- reinicia `nvim`

#### Usar con Nix / Home Manager
Luego aplica los dotfiles:
```bash
cd ~/dotfiles
update   # o: nix run . -- switch --flake . -b backup
```

---

## 📖 Uso Diario

### 🔄 Actualizar configuración

**El alias `update` detecta automáticamente tu sistema:**

```bash
# En cualquier sistema, solo escribe:
update

# En NixOS: hace 'sudo nixos-rebuild switch'
# En Ubuntu/WSL: hace 'home-manager switch'
```

**O usa los comandos específicos:**

```bash
update-home      # Solo actualiza Home Manager
update-system    # Solo actualiza el sistema NixOS (requiere sudo)
```

### ✏️  Editar configuración

```bash
ez               # Abre home.nix en Neovim
```

Después de editar:
```bash
update
```

### 🔍 Buscar paquetes

```bash
nix search nixpkgs <nombre-paquete>
# O visita: https://search.nixos.org/packages
```

### ➕ Agregar nuevo paquete

Edita `home.nix`:
```nix
home.packages = with pkgs; [
  # ... paquetes existentes ...
  tu-nuevo-paquete
];
```

Luego: `update`

---

## 🎯 Comandos según el Sistema

### En NixOS

```bash
# Actualizar TODO (sistema + home)
sudo nixos-rebuild switch --flake ~/dotfiles
# o simplemente:
update

# Solo actualizar Home Manager
home-manager switch --flake ~/dotfiles
# o:
update-home

# Garbage collection
sudo nix-collect-garbage -d
nix-collect-garbage -d  # Solo paquetes de usuario
```

### En Ubuntu/WSL

```bash
# Actualizar configuración
home-manager switch --flake ~/dotfiles
# o:
update

# Garbage collection
nix-collect-garbage -d
```

---

## 🔧 Diferencias Clave

### ¿Qué va en cada archivo?

| Archivo | Propósito | Sistemas |
|---------|-----------|----------|
| `home.nix` | Paquetes y configs de usuario | **Todos** |
| `configuration.nix` | Sistema operativo, servicios, bootloader | **Solo NixOS** |
| `flake.nix` | Orquesta todo | **Todos** |

### ¿Qué hace cada comando?

| Comando | Ubuntu/WSL | NixOS |
|---------|------------|-------|
| `update` | Actualiza Home Manager | Actualiza sistema + Home |
| `update-home` | Actualiza Home Manager | Solo Home Manager |
| `update-system` | ❌ No aplica | Solo sistema NixOS |

---

## 🔄 Sincronizar entre máquinas

```bash
# En la máquina donde hiciste cambios:
cd ~/dotfiles
git add .
git commit -m "Added new package"
git push

# En otra máquina:
cd ~/dotfiles
git pull
update
```

---

## 🆘 Troubleshooting

### "zsh: command not found: home-manager"

```bash
# Asegúrate de que Nix esté en tu PATH
source ~/.nix-profile/etc/profile.d/nix.sh
```

### "Permission denied" en NixOS

Usa `sudo` para comandos del sistema:
```bash
sudo nixos-rebuild switch --flake ~/dotfiles
```

### Los iconos no se ven en WSL

Instala una Nerd Font en Windows Terminal (como JetBrainsMono Nerd Font).

### Conflicto con ~/.zshrc existente

Home Manager crea su propio `.zshrc`. Si tienes uno, renómbralo:
```bash
mv ~/.zshrc ~/.zshrc.backup
```

---

## 🌟 Ventajas de esta configuración

✅ **Un solo repositorio** para todos tus sistemas
✅ **Reproducible**: Misma config en cualquier máquina
✅ **Declarativo**: Todo está en archivos de texto
✅ **Versionado**: Git controla todos los cambios
✅ **Rollback fácil**: Vuelve a versiones anteriores con git
✅ **No más scripts de instalación**: Nix hace todo

---

## 📚 Recursos

- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nixpkgs Search](https://search.nixos.org/packages)

---

Made with ❤️ and Nix
