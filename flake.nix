{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} {
    systems = ["x86_64-linux"];

    imports = [inputs.hercules-ci-effects.flakeModule];
    
    hercules-ci.github-pages.branch = "master";
  
    perSystem = {pkgs, lib ,config, ...}: {      
      packages = {
        default = config.packages.nixos-devops-talk;
	
	reveal-js = pkgs.fetchFromGitHub {
	  owner = "hakimel";
	  repo = "reveal.js";
	  rev = "4.6.0";
	  hash = "sha256-a+J+GasFmRvu5cJ1GLXscoJ+owzFXsLhCbeDbYChkyQ=";
	};
	
        emacs = (pkgs.emacsPackagesFor pkgs.emacs29).emacsWithPackages (epkgs: [epkgs.org-re-reveal]);
	
        emacsExportScript = pkgs.writeScriptBin "emacs-export.el" ''
          #!${lib.getExe config.packages.emacs} --script
          (require 'org-re-reveal)
          (switch-to-buffer (find-file (car argv)))
          (org-re-reveal-export-to-html)
        '';
	
        nixos-devops-talk = pkgs.runCommandNoCC "nixos-devops-talk" {
          buildInputs = [config.packages.emacsExportScript];
        } ''
          cp ${./README.org} talk.org
          emacs-export.el talk.org
	  mkdir -p $out/reveal.js
          cp -r ${config.packages.reveal-js}/{plugin,dist} $out/reveal.js/
          mv talk.html $out/index.html
        '';
      };

      hercules-ci.github-pages.settings.contents = config.packages.nixos-devops-talk;
    };
  };
}
