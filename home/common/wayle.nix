{
  pkgs,
  unstable,
  ...
}: let
  wayle-with-teams-icon = pkgs.symlinkJoin {
    name = "wayle";
    paths = [unstable.wayle];
    postBuild = ''
      mkdir -p $out/share/icons/hicolor/scalable/actions
      cat > $out/share/icons/hicolor/scalable/actions/tb-brand-teams-symbolic.svg << 'EOF'
<svg width='16' height='16' viewBox='0 0 24 24'
     xmlns:gpa='https://www.gtk.org/grappa'
     gpa:version='1'>
  <path d='M3 7h10v10h-10l0 -10'
        stroke-width='2'
        stroke-linecap='round'
        stroke-linejoin='round'
        stroke='rgb(0,0,0)'
        fill='none'
        class='foreground-stroke transparent-fill'
        gpa:stroke='foreground'/>
  <path d='M6 10h4'
        stroke-width='2'
        stroke-linecap='round'
        stroke-linejoin='round'
        stroke='rgb(0,0,0)'
        fill='none'
        class='foreground-stroke transparent-fill'
        gpa:stroke='foreground'/>
  <path d='M8 10v4'
        stroke-width='2'
        stroke-linecap='round'
        stroke-linejoin='round'
        stroke='rgb(0,0,0)'
        fill='none'
        class='foreground-stroke transparent-fill'
        gpa:stroke='foreground'/>
  <path d='M8.104 17c.47 2.274 2.483 4 4.896 4a5 5 0 0 0 5 -5v-7h-5'
        stroke-width='2'
        stroke-linecap='round'
        stroke-linejoin='round'
        stroke='rgb(0,0,0)'
        fill='none'
        class='foreground-stroke transparent-fill'
        gpa:stroke='foreground'/>
  <path d='M18 18a4 4 0 0 0 4 -4v-5h-4'
        stroke-width='2'
        stroke-linecap='round'
        stroke-linejoin='round'
        stroke='rgb(0,0,0)'
        fill='none'
        class='foreground-stroke transparent-fill'
        gpa:stroke='foreground'/>
  <path d='M13.003 8.83a3 3 0 1 0 -1.833 -1.833'
        stroke-width='2'
        stroke-linecap='round'
        stroke-linejoin='round'
        stroke='rgb(0,0,0)'
        fill='none'
        class='foreground-stroke transparent-fill'
        gpa:stroke='foreground'/>
  <path d='M15.83 8.36a2.5 2.5 0 1 0 .594 -4.117'
        stroke-width='2'
        stroke-linecap='round'
        stroke-linejoin='round'
        stroke='rgb(0,0,0)'
        fill='none'
        class='foreground-stroke transparent-fill'
        gpa:stroke='foreground'/>
</svg>
EOF
    '';
  };
in {
  services.wayle = {
    enable = true;
    package = wayle-with-teams-icon;
  };
}
