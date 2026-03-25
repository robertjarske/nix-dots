{unstable, ...}: {
  environment.systemPackages = [
    unstable.php85
    unstable.php85Packages.composer
  ];
}
