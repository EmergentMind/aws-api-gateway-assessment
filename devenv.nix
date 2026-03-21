{ pkgs, ... }:

{
  env.GREET = "devenv";
  dotenv.enable = true;

  packages = [
    pkgs.git
    pkgs.nodejs_24
    pkgs.uv
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
    python = {
      enable = true;
      version = "3.13";
      venv.enable = true;

      venv.requirements = ''
        coverage
        python-dotenv
      '';

      uv = {
        enable = true;
        sync.enable = true; # handles pyproject.toml install
      };

      libraries = [
        pkgs.python313Packages.python-dotenv
      ];
    };
  };
  git-hooks.hooks = {
    prettier.enable = true;
  };
}
