{
config,
lib,
...
}:
let
    inherit (builtins) attrNames;
    inherit (lib) mkOption types;

    themeMapping = {
        dracula = {
            delta-pager = "Dracula";
        };
        gruvbox-light = {
            delta-pager = "gruvbox-light";
        };
    };

    current = themeMapping."${config.dusk.theme}";
in
{
    options.dusk.theme = mkOption {
        type = types.enum (attrNames themeMapping);
        default = "gruvbox-light";
    };

    config = {
        programs.git.delta.options.theme = current.delta-pager;
    };
}
