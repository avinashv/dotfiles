-- LSP, completion, and treesitter configuration
return {

	-- Lazydev: properly configures lua_ls for Neovim Lua development
	-- Eliminates "undefined global vim/require" warnings
	{
		"folke/lazydev.nvim",
		ft = "lua", -- only loads when editing Lua files
		opts = {
			library = {
				-- Load luvit types for vim.uv
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},

	-- Treesitter: syntax highlighting and code understanding
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			---@diagnostic disable-next-line: missing-fields
			require("nvim-treesitter.configs").setup({
				-- Only Lua is auto-installed, add languages as needed
				ensure_installed = { "lua", "luadoc", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
				sync_install = false,
				auto_install = true,
				highlight = {
					enable = true,
					-- Disable for large files
					disable = function(_, buf)
						local max_filesize = 100 * 1024 -- 100 KB
						local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
						if ok and stats and stats.size > max_filesize then
							return true
						end
					end,
				},
				indent = { enable = true },
			})
		end,
	},

	-- Mason: portable package manager for LSP servers, formatters, linters
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		config = function()
			require("mason").setup({
				ui = {
					border = "rounded",
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
		end,
	},

	-- Mason-lspconfig: auto-install LSP servers
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-lspconfig").setup({
				-- Only Lua is auto-installed, add servers as needed
				ensure_installed = { "lua_ls" },
				-- Auto install servers when you open a file that needs them
				automatic_installation = true,

				handlers = {
					-- auto-enable any installed server
					function(server_name)
						vim.lsp.enable(server_name)
					end,
				},
			})
		end,
	},

	-- Nvim-lspconfig: provides server configs (data only, no framework)
	-- The actual LSP setup uses vim.lsp.config (Neovim 0.11+ native API)
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"folke/lazydev.nvim",
		},
		config = function()
			-- Diagnostic configuration
			vim.diagnostic.config({
				virtual_text = { source = "if_many" },
				float = { border = "rounded" },
				severity_sort = true,
			})

			-- LSP keymaps (only active when LSP attaches to buffer)
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					-- Navigation
					map("gd", require("telescope.builtin").lsp_definitions, "Go to definition")
					map("gD", vim.lsp.buf.declaration, "Go to declaration")
					map("gr", require("telescope.builtin").lsp_references, "Go to references")
					map("gI", require("telescope.builtin").lsp_implementations, "Go to implementation")
					map("gy", require("telescope.builtin").lsp_type_definitions, "Go to type definition")

					-- Information
					map("K", vim.lsp.buf.hover, "Hover documentation")
					map("<C-k>", vim.lsp.buf.signature_help, "Signature help")

					-- Code actions and refactoring
					map("<leader>ca", vim.lsp.buf.code_action, "Code action")
					map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")

					-- Workspace
					map("<leader>cwa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
					map("<leader>cwr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
					map("<leader>cwl", function()
						print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, "List workspace folders")

					-- Search symbols
					map("<leader>ss", require("telescope.builtin").lsp_document_symbols, "Document symbols")
					map("<leader>sS", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Workspace symbols")

					-- Diagnostics
					map("<leader>cd", vim.diagnostic.open_float, "Show diagnostic")

					-- Format on demand
					map("<leader>cf", function()
						vim.lsp.buf.format({ async = true })
					end, "Format buffer")

					-- Toggle inlay hints if supported
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.server_capabilities.inlayHintProvider then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "Toggle inlay hints")
					end
				end,
			})

			-- Format on save
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = vim.api.nvim_create_augroup("lsp-format", { clear = true }),
				callback = function()
					local clients = vim.lsp.get_clients({ bufnr = 0 })
					for _, client in ipairs(clients) do
						if client.server_capabilities.documentFormattingProvider then
							vim.lsp.buf.format({ async = false })
							return
						end
					end
				end,
			})

			-- Shared capabilities (enables completion via blink.cmp)
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- Global config for all LSP servers (root markers, capabilities)
			vim.lsp.config("*", {
				root_markers = { ".git" },
				capabilities = capabilities,
			})

			-- Lua language server (configured for Neovim)
			-- Note: lazydev.nvim handles the workspace library setup automatically
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						hint = { enable = true },
					},
				},
			})

			-- Enable the LSP servers you want
			-- Add more servers here as needed: "pyright", "ts_ls", "rust_analyzer", etc.
			vim.lsp.enable({ "lua_ls" })
		end,
	},

	-- Blink.cmp: fast completion engine
	{
		"saghen/blink.cmp",
		version = "*", -- use latest release
		dependencies = {
			"rafamadriz/friendly-snippets", -- snippet collection
		},
		event = "InsertEnter",
		config = function()
			require("blink.cmp").setup({
				keymap = {
					preset = "default",
					-- Tab/Shift-Tab to navigate completion menu
					["<Tab>"] = { "select_next", "fallback" },
					["<S-Tab>"] = { "select_prev", "fallback" },
					-- Enter to confirm selection
					["<CR>"] = { "accept", "fallback" },
					-- Ctrl+Space to trigger completion manually
					["<C-Space>"] = { "show", "fallback" },
					-- Ctrl+e to cancel
					["<C-e>"] = { "cancel", "fallback" },
					-- Scroll documentation
					["<C-d>"] = { "scroll_documentation_down", "fallback" },
					["<C-u>"] = { "scroll_documentation_up", "fallback" },
				},
				completion = {
					-- Show documentation preview
					documentation = {
						auto_show = true,
						auto_show_delay_ms = 200,
					},
					menu = {
						border = "rounded",
						draw = {
							columns = {
								{ "label", "label_description", gap = 1 },
								{ "kind" },
							},
						},
					},
				},
				snippets = { preset = "default" },
				sources = {
					default = { "lazydev", "lsp", "path", "snippets", "buffer" },
					providers = {
						-- Lazydev completion for require statements (prioritized)
						lazydev = {
							name = "LazyDev",
							module = "lazydev.integrations.blink",
							score_offset = 100,
						},
					},
				},
			})
		end,
	},
}
