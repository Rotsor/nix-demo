# external dependencies
let nixpkgs = import <nixpkgs> {}; in
let busybox = nixpkgs.busybox; in
let gnutar = nixpkgs.gnutar; in

# All the input files that we need.
# We abuse the record type to serve as a Map.
# It's surprisingly very suitable for that.
#
#   input_files :: Map Basename Path
#
let input_files = {
  "rubbish.bin" = ./rubbish.bin;
  "README" = ./README;
  "LICENSE" = ./LICENSE;
  "docs.txt" = ./docs.txt;
  "bins.txt" = ./bins.txt;
}; in


# Lookup in [input_files]
#
#  input_file :: Basename -> Path
#
let input_file =
  name : builtins.getAttr name input_files;
in

# the only form of derivation that we will need
# is a script that reads some hard-coded inputs and writes
# its output into $out.
# This function takes such a script and returns the
# path to the result. (which is going to be built lazily)
# 
#   run_script :: Script -> Path
#
let run_script = name : script : derivation {
  system = "x86_64-linux"; # also works on Windows+WSL
  name = "script-output"; # name is not used for anything important
  builder = "${busybox}/bin/sh";
  args = [ "-c" "echo RUNNING: ${name}; ${script}" ];
}; in

# concatenate two files
#
#   cat :: Path -> Path -> Path
#
let concat = file1 : file2 :
  run_script "cat" "${busybox}/bin/cat ${file1} ${file2} > $out";
in

# collect a bunch of loose files into one directory
#
#   construct_directory :: [{ name :: Basename, value :: Path }] -> Path
#
let construct_directory = files :
  run_script "construct-directory" (
    builtins.concatStringsSep "; "
      ([
      "${busybox}/bin/mkdir $out"
      "cd $out"
      ] ++
      map (file : "${busybox}/bin/cp ${file.value} ${file.name}") files));
in

# create a tar archive
#
#   tar :: [{ name :: Basename, value :: Path }] -> Path
#
let tar = files :
  let directory = construct_directory files; in
  let names = map (file : "${file.name}") files; in
  run_script "tar"
  ''
    cd ${directory}
    ${gnutar}/bin/tar -cf "$out" ${builtins.concatStringsSep " " names}
  '';
in

# Split a multiplne string into individual lines.
#
#   lines :: String -> [ String ]
#
let concatMap = f: list: builtins.concatLists (map f list); in
let lines = s :
  concatMap
    (s : if builtins.isList s || s == "" || s == "\n" then [] else [s])
    (builtins.split "\n" s);
in

#
#   release_txt :: Path
#
let release_txt = concat (input_file "bins.txt") (input_file "docs.txt"); in

#
#   release_tar :: Path
#
let release_tar =
  let release_files = lines (builtins.readFile release_txt); in
  tar (
    map (name :
      { name = name; value = input_file name; })
    release_files);
in
release_tar
