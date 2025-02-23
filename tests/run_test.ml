let timeout = 10 * 60
let test = Sys.argv.(1)
let cmd = Sys.argv.(2)
let args = try Array.sub Sys.argv 2 (Array.length Sys.argv - 2) with _ -> [||]
let logfile = Filename.temp_file "test" test
let stdin_file = Filename.null
let cleanup () = try Unix.unlink logfile with _ -> ()

let run () =
  let start_time = Unix.time () in
  let stdin = Unix.openfile stdin_file [Unix.O_RDWR] 0o644 in
  let stdout = Unix.openfile logfile [Unix.O_RDWR] 0o644 in

  let print_log () =
    try
      Unix.close stdout;
      let buffer_size = 1024 in
      let buffer = Bytes.create buffer_size in
      let fd = Unix.openfile logfile [Unix.O_RDONLY] 0 in
      let rec loop () =
        match Unix.read fd buffer 0 buffer_size with
          | 0 -> ()
          | _ ->
              Printf.eprintf "%s" (Bytes.unsafe_to_string buffer);
              loop ()
      in
      loop ();
      print_newline ();
      Unix.close fd
    with _ -> ()
  in

  let warning_prefix, error_prefix =
    if Sys.getenv_opt "GITHUB_ACTIONS" <> None then
      ( Printf.sprintf "::warning file=%s,title=Test skipped::" test,
        Printf.sprintf "::error file=%s,title=Test failed::" test )
    else ("", "")
  in

  let runtime () =
    let runtime = Unix.time () -. start_time in
    let min = runtime /. 60. in
    let sec = runtime -. (min *. 60.) in
    (int_of_float min, int_of_float sec)
  in

  let on_timeout () =
    let min, sec = runtime () in
    Printf.eprintf
      "%sRan test \027[1m%s\027[0m: \027[1;34m[timeout]\027[0m (Test time: \
       %02dm:%02ds)\n"
      error_prefix test min sec;
    print_log ();
    cleanup ();
    exit 1
  in

  ignore
    (Thread.create
       (fun () ->
         Unix.sleep timeout;
         on_timeout ())
       ());

  let pid = Unix.create_process cmd args stdin stdout stdout in

  match Unix.waitpid [] pid with
    | _, Unix.WEXITED 0 ->
        let min, sec = runtime () in
        Printf.eprintf
          "Ran test \027[1m%s\027[0m: \027[0;32m[ok]\027[0m (Test time: \
           %02dm:%02ds)\n"
          test min sec;
        if Sys.getenv_opt "LIQ_VERBOSE_TEST" <> None then print_log ();
        cleanup ();
        exit 0
    | _, Unix.WEXITED 2 ->
        Printf.eprintf
          "%sRan test \027[1m%s\027[0m: \027[1;33m[skipped]\027[0m\n"
          warning_prefix test;
        exit 0
    | _ ->
        let min, sec = runtime () in
        Printf.eprintf
          "%sRan test \027[1m%s\027[0m: \027[0;31m[failed]\027[0m (Test time: \
           %02dm:%02ds)\n"
          error_prefix test min sec;
        print_log ();
        exit 1

let () =
  try run ()
  with exn ->
    let bt = Printexc.get_raw_backtrace () in
    cleanup ();
    Printexc.raise_with_backtrace exn bt
