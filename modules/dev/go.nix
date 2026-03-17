{unstable, ...}: {
  environment.systemPackages = with unstable; [
    go
    gopls # language server
    gotools # goimports, godoc, etc.
  ];

  environment.variables = {
    GOPATH = "$HOME/go";
  };
}
