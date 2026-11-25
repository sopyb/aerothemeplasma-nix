{
  kdePackages,
  fetchFromGitLab,
  fetchzip,
  runCommand,
  diffutils,
  lib
}:
let
  patch-source = fetchFromGitLab {
    domain = "gitgud.io";
    owner = "aeroshell";
    repo = "libplasma";
    rev = "5f1811a0d9a66a33d5c927508f8bc3231923d443";
    hash = "sha256-8SO/gIPUljbXKacfz3Ku64y7kvz+fpt49taAjUqF0hA=";
    forceFetchGit = true;
  };
  patch-target = fetchzip {
    url = "mirror://kde/stable/plasma/6.8.3/libplasma-6.8.3.tar.xz";
    hash = "sha256-8SO/gIPUljbXKacfz3Ku64y7kvz+fpt49taAjUqF0hA=";
  };
in
kdePackages.libplasma.overrideAttrs (oldAttrs: {
  pname = "aeroshell-libplasma";
  patches = [(
    runCommand "aeroshell-libplasma-patches" { nativeBuildInputs = [diffutils]; } ''
      cd ${patch-source}
      diff -ru ${patch-target}/src ./src > $out || test $? -eq 1
    ''
  )];
  postPatch = ''
    shopt -s globstar

    substituteInPlace src/**/CMakeLists.txt \
      --replace-warn 'URI "org.kde.plasma.' 'URI "io.gitgud.wackyideas.plasma.' \
      --replace-warn "EXPORT_NAME Plasma" "OUTPUT_NAME ATPlasma"
    substituteInPlace src/**/*.qml --replace-quiet "import org.kde.plasma." "import io.gitgud.wackyideas.plasma."

    substituteInPlace src/declarativeimports/core/tooltipdialog.cpp --replace-fail \
      'component(m_engine.get(), "org.kde.plasma.' 'component(m_engine.get(), "io.gitgud.wackyideas.plasma.'

    substituteInPlace src/declarativeimports/CMakeLists.txt --replace-fail "add_subdirectory(kirigamiplasmastyle)" ""
    substituteInPlace src/plasma/CMakeLists.txt --replace-fail "add_subdirectory(packagestructure)" ""
  '';
  ninjaFlags = ["corebindingsplugin"];
  postFixup = "rm -rf $out/share";
})
