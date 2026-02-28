-- Set leader key to space (must happen before lazy.nvim loads)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable netrw (we use neo-tree instead)
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

-- Use Nerd Font (required for icons in neo-tree, lualine, etc.)
vim.g.have_nerd_font = true

-- Line numbers: show absolute current line, relative for others
vim.opt.number = true
vim.opt.relativenumber = true

-- Enable mouse in all modes (useful for resizing splits)
vim.opt.mouse = "a"

-- Hide mode from cmdline since lualine shows it
vim.opt.showmode = false

-- Sync clipboard with system (uses pbcopy on mac)
vim.opt.clipboard = "unnamedplus"

-- Indentation: keep indent when wrapping lines
vim.opt.breakindent = true

-- Persistent undo: survive after closing file
vim.opt.undofile = true

-- Search: case-insensitive unless capital letters used
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn always visible (prevents layout shift)
vim.opt.signcolumn = "yes"

-- Faster update time (affects CursorHold events, gitsigns)
vim.opt.updatetime = 250

-- Time to wait for mapped sequence to complete (ms)
vim.opt.timeoutlen = 300

-- How new splits open
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Show whitespace characters
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Live preview of substitutions as you type
vim.opt.inccommand = "split"

-- Highlight current line
vim.opt.cursorline = true

-- Minimum lines to keep above/below cursor when scrolling
vim.opt.scrolloff = 10

-- Tabs: use 2 spaces (change to 4 if you prefer)
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Enable 24-bit RGB colors (works in ghostty)
vim.opt.termguicolors = true

-- vim indenting as fallback
vim.cmd("filetype plugin indent on")

-- Exit insert mode with jk (faster than reaching for escape)
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Move lines up/down with Option+j/k (mac/ghostty compatible)
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down", silent = true })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up", silent = true })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Clear search highlight on pressing escape
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Quickfix navigation (useful with trouble.nvim too)
vim.keymap.set("n", "[q", "<cmd>cprev<CR>", { desc = "Previous quickfix item" })
vim.keymap.set("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix item" })

-- Diagnostic navigation (jump between errors/warnings)
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1 })
end, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1 })
end, { desc = "Next diagnostic" })

-- Window navigation with Ctrl+hjkl (tmux-navigator handles tmux panes)
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Focus below window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Focus above window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })

-- Resize windows with Ctrl+arrows
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Better indenting in visual mode (keeps selection)
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Highlight text on yank (brief flash to confirm)
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Restore cursor position when reopening files
vim.api.nvim_create_autocmd("BufReadPost", {
	desc = "Return cursor to last position",
	group = vim.api.nvim_create_augroup("restore-cursor", { clear = true }),
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Bootstrap lazy.nvim (auto-install if not present)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins from lua/plugins.lua and lua/lsp.lua
require("lazy").setup({
	require("plugins"),
	require("lsp"),
}, {
	-- Check for plugin updates but don't notify every time
	checker = { enabled = true, notify = false },
	-- Disable change detection notifications
	change_detection = { notify = false },
})
