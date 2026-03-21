{ pkgs, ... }:

{
  env.GREET = "devenv";
  dotenv.enable = true;

  packages = [
    pkgs.git
    pkgs.nodejs_24
  ];

  languages = {
    typescript.enable = true;
    javascript = {
      enable = true;
      pnpm = {
        enable = true;
        install.enable = true;
      };
    };
  };
  git-hooks.hooks = {
    prettier.enable = true;
  };

}
