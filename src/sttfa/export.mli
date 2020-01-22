(** Functions to write files in a foreign system.  Available systems
    are the ones described by the type {!type:Systems.system}. *)

val export_to_system_as_string : Core.Systems.t -> Ast.item -> string

val export_to_system_as_ast : Core.Systems.t ->
  Format.formatter -> ?mdeps:Ast.mdeps -> Ast.ast -> unit

val mk_ast : Kernel.Basic.mident -> Parsing.Entry.entry list -> Ast.ast

(*
open Core

(** E is the signature for an exporting system. *)
module type E =
sig
  val system            : Systems.t
  (** System identifier. *)

  val extension         : string
  (** Extension of the files from this system. *)

  val print_ast         : Format.formatter -> ?mdeps:Ast.mdeps -> Ast.ast
    -> unit
  (** [print_ast fmt ?mdeps ast] prints Sttfa abstract syntax tree
      [ast] to formatter [fmt]
      TODO document ?mdeps. *)

  val string_of_item : Ast.item -> string
end

val of_system : Systems.t -> (module E)
(** [of_system s] returns the module associated to system id [s]. *)

val export_system : (module E) -> string -> Format.formatter -> unit
(** [export_system Exp f out] exports file [f] using module [Exp] to format
    [out]. *)
*)
