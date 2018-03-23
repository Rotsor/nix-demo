# external dependencies
let nixpkgs = import <nixpkgs> {}; in
let busybox = nixpkgs.busybox; in
let gnutar = nixpkgs.gnutar; in

let concat = file1 : file2 : derivation {
  system = "x86_64-linux";
  name = "concatenated";
  builder = "${busybox}/bin/sh";
  args = [ "-c" "echo RUNNING: concat ${file1} ${file2}; ${busybox}/bin/cat ${file1} ${file2} > $out" ];
}; in
let other_files = {
  "rubbish.bin" = ./rubbish.bin;
  "README" = ./README;
  "LICENSE" = ./LICENSE;
}; in

let construct_directory = files :
  let build_script =
    builtins.concatStringsSep "; "
      ([
      "echo RUNNING: collecting files: ${builtins.concatStringsSep " " (map (file : file.name) files)}"
      "${busybox}/bin/mkdir $out"
      "cd $out"
      ] ++
      map (file : "${busybox}/bin/cp ${file.value} ${file.name}") files);
  in
  derivation
  {
    system = "x86_64-linux";
    name = "constructed";
    builder = "${busybox}/bin/sh";
    args = [ "-c" build_script ];
  };
in

let tar = files :
  let directory = construct_directory files; in
  let s = (
      builtins.concatStringsSep " " (
        [
         "echo RUNNING: tar;"
         "cd ${directory};"
         "${gnutar}/bin/tar -cf $out" ]
        ++
        map (file : "${file.name}") files)); in
  derivation {
    system = "x86_64-linux";
    name = "tarred";
    builder = "${busybox}/bin/sh";
    args = [ "-c" s ];
  }
 ;
in

let attrsToList = e : map (name : { name = name; value = builtins.getAttr name e; }) (builtins.attrNames e); in

let concatMap = f: list: builtins.concatLists (map f list); in
let linesQ = s :
  let split = builtins.split "\n" s; in
  concatMap (s : if builtins.isList s || s == "" || s == "\n" then [] else [s]) split
  ;
in

let result_txt = concat ./bins.txt ./docs.txt; in
let release_tar =
  let lines = linesQ (builtins.readFile result_txt); in
  tar (
    map (name :
      { name = name; value = builtins.getAttr name other_files; }) lines);
in
release_tar