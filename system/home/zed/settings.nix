{ pkgs, ... }:
{
  assistant = {
    version = "2";
    default_model = {
      provider = "anthropic";
      model = "claude-3-5-sonnet-20240620";
    };
  };
  auto_update = false;
  buffer_font_family = "BerkeleyMono Nerd Font Mono";
  buffer_font_size = 16;
  buffer_line_height = {
    custom = 1.4;
  };
  calls = {
    mute_on_join = false;
    share_on_join = false;
  };
  load_direnv = "shell_hook";
  file_scan_exclusions = [
    "**/.direnv"
    "**/.git"
    "**/.svn"
    "**/.hg"
    "**/CVS"
    "**/.DS_Store"
    "**/Thumbs.db"
    "**/.classpath"
    "**/.settings"
  ];
  file_types = {
    JSON = [ "flake.lock" ];
    TOML = [ "Cargo.lock" ];
  };
  git.inline_blame.enabled = false;
  inline_completions.disabled_globs = [
    ".env"
    ".direnv"
  ];
  lsp = {
    rust-analyzer = {
      initialization_options = {
        cargo = {
          buildScripts.enable = true;
          allTargets = false;
        };
        hover = {
          actions = {
            implementations = true;
            references = true;
            run = true;
          };
        };
        imports.preferPrelude = true;
        inlayHints = {
          maxLength = null;
          lifetimeElisionHints = {
            useParameterNames = true;
            enable = "skip_trivial";
          };
          closureReturnTypeHints.enable = "always";
        };
        procMacro.enable = true;
        rust.analyzerTargetDir = true;
      };
    };
  };
  outline_panel = {
    button = false;
  };
  preferred_line_length = 102;
  private_files = [
    "**/.env*"
    "**/*.pem"
    "**/*.key"
    "**/*.cert"
    "**/*.crt"
    "**/secrets.yml"
    "**/.direnv"
    "**/target"
  ];
  project_panel.scrollbar.show = "never";
  restore_on_startup = "none";
  show_whitespaces = "boundary";
  soft_wrap = "preferred_line_length";
  tab_bar = {
    show = false;
  };
  telemetry = {
    diagnostics = false;
    metrics = false;
  };
  terminal = {
    detect_venv = "off";
    font_size = 15;
    line_height.custom = 1.4;
    max_scroll_history_lines = 10000;
    shell.program = "${pkgs.bashInteractive}/bin/bash";
    working_directory = "current_project_directory";
  };
  theme = {
    mode = "system";
    light = "Catppuccin Mocha";
    dark = "Catppuccin Mocha";
  };
  toolbar = {
    breadcrumbs = false;
    quick_actions = false;
    selections_menu = false;
  };
  ui_font_family = "BerkeleyMono Nerd Font Mono";
  ui_font_size = 16;
  vim = {
    use_system_clipboard = "never";
    use_smartcase_find = true;
  };
  vim_mode = true;
}
