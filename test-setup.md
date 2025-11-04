# Test Neovim Setup

Open this file with: `nvim test-setup.md`

## What to Test:

1. **Theme**: Colors should look good (Dracula)
2. **File Explorer**: Press `Space+e` to see file tree
3. **Find Files**: Press `Space+ff` to search files
4. **Syntax Highlighting**: This markdown should be colorful
5. **LSP**: Open a Python/Lua file for autocomplete

## Test Code:

```python
def hello_world():
    print("Hello from Dracula theme!")
    return True
```

```lua
local function test()
    print("Neovim is awesome!")
    return true
end
```

## Expected Results:

✅ Colors are purple, cyan, pink (Dracula)
✅ Statusline shows at bottom
✅ Buffer tabs show at top
✅ Space+e opens file tree
✅ Space+ff opens fuzzy finder

All working? You're good! 🎉
