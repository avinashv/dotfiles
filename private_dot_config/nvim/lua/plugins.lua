-- All plugins except LSP-related ones (those are in lsp.lua)
return {

    -- Catppuccin colorscheme (mocha variant)
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000, -- load before other plugins so colors are available
      config = function()
        require("catppuccin").setup({
          flavour = "mocha", -- dark variant
          integrations = {
            -- Enable integrations for plugins we use
            gitsigns = true,
            mason = true,
            neotree = true,
            treesitter = true,
            which_key = true,
            flash = true,
            indent_blankline = { enabled = true },
            mini = { enabled = true },
            native_lsp = {
              enabled = true,
              underlines = {
                errors = { "undercurl" },
                hints = { "undercurl" },
                warnings = { "undercurl" },
                information = { "undercurl" },
              },
            },
          },
        })
        vim.cmd.colorscheme("catppuccin")
      end,
    },
  
    -- Which-key: shows available keybindings in popup
    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      config = function()
        local wk = require("which-key")
        wk.setup({
          -- Delay before showing popup (ms)
          delay = 200,
          icons = {
            -- Use nerd font icons
            mappings = true,
            keys = {},
          },
        })
        -- Register key group labels (shows in which-key popup)
        wk.add({
          { "<leader>b", group = "buffer" },
          { "<leader>c", group = "code" },
          { "<leader>f", group = "find" },
          { "<leader>g", group = "git" },
          { "<leader>s", group = "search" },
          { "<leader>t", group = "toggle" },
          { "<leader>x", group = "diagnostics" },
        })
      end,
    },
  
    -- Telescope: fuzzy finder for files, grep, buffers, etc.
    {
      "nvim-telescope/telescope.nvim",
      branch = "0.1.x",
      dependencies = {
        "nvim-lua/plenary.nvim", -- required utility library
        -- Native fzf sorter for better performance
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        "nvim-tree/nvim-web-devicons", -- file icons
      },
      config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")
  
        telescope.setup({
          defaults = {
            -- Open results in bottom pane
            layout_strategy = "horizontal",
            layout_config = { prompt_position = "top" },
            sorting_strategy = "ascending",
            mappings = {
              i = {
                -- Ctrl+j/k to navigate results in insert mode
                ["<C-j>"] = actions.move_selection_next,
                ["<C-k>"] = actions.move_selection_previous,
              },
            },
          },
        })
  
        -- Load fzf extension for faster fuzzy matching
        telescope.load_extension("fzf")
  
        -- Telescope keymaps
        local builtin = require("telescope.builtin")
        vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
        vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Find by grep" })
        vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
        vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help" })
        vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Find recent files" })
        vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "Find word under cursor" })
        vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "Switch buffer" })
  
        -- Search variants
        vim.keymap.set("n", "<leader>s/", builtin.current_buffer_fuzzy_find, { desc = "Search in buffer" })
        vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "Search diagnostics" })
        vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "Search keymaps" })
        vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "Search resume" })
      end,
    },
  
    -- Neo-tree: file explorer sidebar
    {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
      },
      cmd = "Neotree", -- lazy load on command
      keys = {
        { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file explorer" },
        { "<leader>o", "<cmd>Neotree focus<CR>", desc = "Focus file explorer" },
      },
      -- Eagerly load neo-tree when nvim is opened with a directory argument
      -- (needed because netrw is disabled, so the directory buffer is orphaned)
      init = function()
        vim.api.nvim_create_autocmd("BufEnter", {
          group = vim.api.nvim_create_augroup("neotree_start_directory", { clear = true }),
          desc = "Start Neo-tree with directory",
          once = true,
          callback = function()
            if package.loaded["neo-tree"] then
              return
            end
            local argv = vim.fn.argv(0)
            if argv ~= "" then
              local stat = vim.uv.fs_stat(argv)
              if stat and stat.type == "directory" then
                require("neo-tree")
              end
            end
          end,
        })
      end,
      config = function()
        require("neo-tree").setup({
          -- Close neo-tree when opening a file
          close_if_last_window = true,
          filesystem = {
            -- Follow current file
            follow_current_file = { enabled = true },
            -- Use system trash instead of permanent delete
            use_libuv_file_watcher = true,
          },
          window = {
            width = 35,
            mappings = {
              -- Space is leader, use backspace for navigation
              ["<space>"] = "none",
            },
          },
        })
      end,
    },
  
    -- Lualine: statusline
    {
      "nvim-lualine/lualine.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      config = function()
        require("lualine").setup({
          options = {
            theme = "catppuccin",
            -- Rounded separators look cleaner
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
          },
          sections = {
            lualine_a = { "mode" },
            lualine_b = { "branch", "diff", "diagnostics" },
            lualine_c = { { "filename", path = 1 } }, -- show relative path
            lualine_x = { "encoding", "fileformat", "filetype" },
            lualine_y = { "progress" },
            lualine_z = { "location" },
          },
        })
      end,
    },
  
    -- Gitsigns: git status in signcolumn
    {
      "lewis6991/gitsigns.nvim",
      event = { "BufReadPre", "BufNewFile" },
      config = function()
        require("gitsigns").setup({
          signs = {
            add = { text = "│" },
            change = { text = "│" },
            delete = { text = "_" },
            topdelete = { text = "‾" },
            changedelete = { text = "~" },
          },
          -- Gitsigns keymaps
          on_attach = function(bufnr)
            local gs = package.loaded.gitsigns
            local function map(mode, l, r, desc)
              vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
            end
  
            -- Navigation between hunks
            map("n", "]h", gs.next_hunk, "Next git hunk")
            map("n", "[h", gs.prev_hunk, "Previous git hunk")
  
            -- Actions
            map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
            map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
            map("v", "<leader>gs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selection")
            map("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset selection")
            map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
            map("n", "<leader>gu", gs.undo_stage_hunk, "Undo stage hunk")
            map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
            map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
            map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
            map("n", "<leader>gd", gs.diffthis, "Diff against index")
          end,
        })
      end,
    },
  
    -- Snacks.nvim: collection of utilities (lazygit, notifications, etc.)
    {
      "folke/snacks.nvim",
      priority = 1000,
      lazy = false, -- load immediately for dashboard
      config = function()
        local Snacks = require("snacks")
        Snacks.setup({
          -- Dashboard shown on startup
          dashboard = {
            enabled = true,
            sections = {
              { section = "header" },
              { section = "keys", gap = 1, padding = 1 },
              { section = "recent_files", limit = 8, padding = 1 },
              { section = "startup" },
            },
          },
          -- Notification system (replaces vim.notify)
          notifier = { enabled = true },
          -- Indent guides
          indent = { enabled = true },
          -- Highlight word under cursor
          words = { enabled = true },
          -- Lazygit integration
          lazygit = { enabled = true },
        })
  
        -- Snacks keymaps
        vim.keymap.set("n", "<leader>gg", function() Snacks.lazygit() end, { desc = "Open Lazygit" })
        vim.keymap.set("n", "<leader>gl", function() Snacks.lazygit.log() end, { desc = "Lazygit log" })
        vim.keymap.set("n", "<leader>gf", function() Snacks.lazygit.log_file() end, { desc = "Lazygit file log" })
        vim.keymap.set("n", "<leader>tn", function() Snacks.notifier.show_history() end, { desc = "Notification history" })
        vim.keymap.set("n", "<leader>un", function() Snacks.notifier.hide() end, { desc = "Dismiss notifications" })
      end,
    },
  
    -- Todo-comments: highlight and search TODO/FIXME/etc.
    {
      "folke/todo-comments.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      event = { "BufReadPre", "BufNewFile" },
      config = function()
        require("todo-comments").setup({})
        vim.keymap.set("n", "]t", function() require("todo-comments").jump_next() end, { desc = "Next todo comment" })
        vim.keymap.set("n", "[t", function() require("todo-comments").jump_prev() end, { desc = "Previous todo comment" })
        vim.keymap.set("n", "<leader>st", "<cmd>TodoTelescope<CR>", { desc = "Search todos" })
      end,
    },
  
    -- Trouble: pretty diagnostics list
    {
      "folke/trouble.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      cmd = "Trouble",
      keys = {
        { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (trouble)" },
        { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics" },
        { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Symbols (trouble)" },
        { "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<CR>", desc = "LSP info (trouble)" },
        { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix (trouble)" },
      },
      config = function()
        require("trouble").setup({})
      end,
    },
  
    -- Flash: enhanced navigation/motions
    {
      "folke/flash.nvim",
      event = "VeryLazy",
      keys = {
        { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
        { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
        { "r", mode = "o", function() require("flash").remote() end, desc = "Flash remote" },
        { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash treesitter search" },
      },
      config = function()
        require("flash").setup({})
      end,
    },
  
    -- Mini.ai: better around/inside text objects
    {
      "echasnovski/mini.ai",
      event = "VeryLazy",
      config = function()
        require("mini.ai").setup({
          -- Extend with custom text objects
          n_lines = 500, -- search this many lines for text objects
        })
      end,
    },
  
    -- Mini.surround: add/change/delete surroundings
    {
      "echasnovski/mini.surround",
      event = "VeryLazy",
      config = function()
        require("mini.surround").setup({
          -- sa = surround add, sd = surround delete, sr = surround replace
          mappings = {
            add = "sa",
            delete = "sd",
            replace = "sr",
            find = "sf",
            find_left = "sF",
            highlight = "sh",
            update_n_lines = "sn",
          },
        })
      end,
    },
  
    -- Mini.pairs: auto-close brackets, quotes, etc.
    {
      "echasnovski/mini.pairs",
      event = "InsertEnter",
      config = function()
        require("mini.pairs").setup({})
      end,
    },
  
    -- Mini.comment: toggle comments with gcc/gc
    {
      "echasnovski/mini.comment",
      event = "VeryLazy",
      config = function()
        require("mini.comment").setup({})
      end,
    },
  
    -- Tmux navigator: seamless navigation between vim and tmux splits
    {
      "christoomey/vim-tmux-navigator",
      lazy = false, -- load immediately for keymaps to work
      cmd = {
        "TmuxNavigateLeft",
        "TmuxNavigateDown",
        "TmuxNavigateUp",
        "TmuxNavigateRight",
      },
      keys = {
        -- These override the window nav keymaps when tmux is detected
        { "<C-h>", "<cmd>TmuxNavigateLeft<CR>", desc = "Navigate left (vim/tmux)" },
        { "<C-j>", "<cmd>TmuxNavigateDown<CR>", desc = "Navigate down (vim/tmux)" },
        { "<C-k>", "<cmd>TmuxNavigateUp<CR>", desc = "Navigate up (vim/tmux)" },
        { "<C-l>", "<cmd>TmuxNavigateRight<CR>", desc = "Navigate right (vim/tmux)" },
      },
    },
  
    -- Buffer management keymaps
    {
      "echasnovski/mini.bufremove",
      keys = {
        { "<leader>bd", function() require("mini.bufremove").delete(0, false) end, desc = "Delete buffer" },
        { "<leader>bD", function() require("mini.bufremove").delete(0, true) end, desc = "Delete buffer (force)" },
      },
    },
  }