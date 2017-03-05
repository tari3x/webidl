type ast = Ast.definitions [@@deriving show]
type data = Data.definitions [@@deriving show]

type src_type = 
  | File
  | Channel
  | String
[@@deriving show]

type syntax_error = {
  src : string ;
  src_type : src_type ;
  start_pos : int * int ;
  end_pos : int * int ;
  token : string ;
} [@@deriving show]

exception Syntax_error of syntax_error

let get_error_info src src_type lexbuf =
  let open Lexing in
  let start = Lexing.lexeme_start_p lexbuf in
  let end_ = Lexing.lexeme_end_p lexbuf in
  let token = Lexing.lexeme lexbuf in
  let start_pos = (start.pos_lnum, (start.pos_cnum - start.pos_bol + 1)) in
  let end_pos = (end_.pos_lnum, (end_.pos_cnum - end_.pos_bol + 1)) in
  {src; src_type; start_pos; end_pos; token}

let main ?(trace = false) src src_type lexbuf =
  let _ = Parsing.set_trace trace in
  try
    Syntax.Parser.main Syntax.Lexer.read lexbuf 
  with
  | Syntax.Parser.Error ->
    let syntax_error = get_error_info src src_type lexbuf in
    raise (Syntax_error syntax_error)

let ast_from_string src_name input_string =
  let lexbuf = Lexing.from_string input_string in
  main src_name String lexbuf

let ast_from_channel src_name input_channel =
  let lexbuf = Lexing.from_channel input_channel in
  main src_name Channel lexbuf

let ast_from_file file_name =
  let input_channel = open_in file_name in
  let lexbuf = Lexing.from_channel input_channel in
  main file_name File lexbuf

let data_from_string src_name input_string : data =
  ast_from_string src_name input_string
  |> Ast_to_data.of_difinitions

let data_from_channel src_name input_channel : data =
  ast_from_channel src_name input_channel
  |> Ast_to_data.of_difinitions

let data_from_file file_name : data =
  ast_from_file file_name 
  |> Ast_to_data.of_difinitions