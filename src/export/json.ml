(** Export to json files. *)

open Extras
module B = Basic
module D = Dep
module E = Entry
module F = Format
module S = Signature
module T = Term
module U = Uri
module Jt = Json_types
module Tx = Taxonomy

(** Information collected in the current time. *)
type content =
  { ct_taxo : Tx.Sttfa.t D.NameMap.t
  (** Taxons of the file. *)
  ; ct_deps : (B.name list) D.NameMap.t
  (** Dependencies *)
  ; ct_thax : (B.name list) D.NameMap.t
  (** Axiomatic theories *)}

(** [find_taxon ct n] searches for taxon of [n] in the current content [ct] and
    hands over {!val:Tx.find_taxon} if it is not found. *)
let find_taxon : content -> B.name -> Tx.Sttfa.t = fun ct nm ->
  try D.NameMap.find nm ct.ct_taxo
  with Not_found -> Tx.find_taxon nm

(** [ppt_of_dkterm md tx te] converts Dedukti term [te] from Dedukti
    module [md] into a JSON ppterm of taxonomy [tx]. *)
let rec ppt_of_dkterm : B.mident -> content -> T.term -> Jt.Ppterm.t =
  fun md acc t ->
  ppt_of_dkterm_args md acc t []

(** [ppt_of_dkterm_args md tx te stk] converts Dedukti term [te] from
    module [md] applied to stack of arguments [stk].  [tx] is the taxon of
    [te]. *)
and ppt_of_dkterm_args : B.mident -> content -> T.term -> T.term list -> Jt.Ppterm.t =
  fun md acc t stk ->
  let ppt_of_dkterm = ppt_of_dkterm md acc in
  let ppt_of_dkterm_args = ppt_of_dkterm_args md acc in
  match t with
  | T.Kind -> Jt.Ppterm.Const { c_symb = "Kind" ; c_args = [] }
  | T.Type(_) -> Jt.Ppterm.Const { c_symb = "Type" ; c_args = [] }
  | T.DB(_,id,_) ->
    let v_args = List.map ppt_of_dkterm stk in
    Jt.Ppterm.Var { v_symb = B.string_of_ident id ; v_args}
  | T.Const(_,name) ->
    let c_args = List.map ppt_of_dkterm stk in
    let c_symb =
      let cmd = B.md name in
      let cid = B.id name in
      let c_tx = find_taxon acc name in
      let tx = Tx.Sttfa.to_string ~short:true c_tx in
      U.of_dkname (B.mk_name cmd cid) Tx.Sttfa.theory tx |> U.to_string
    in
    Jt.Ppterm.Const { c_symb ; c_args }
  | T.App(t,u,vs) -> ppt_of_dkterm_args t (u :: vs @ stk)
  | T.Lam(_,id,annot,t) ->
    let bound = B.string_of_ident id in
    let annotation = Option.map ppt_of_dkterm annot in
    let b_args = List.map ppt_of_dkterm stk in
    Jt.Ppterm.Binder { b_symb = "λ" ; bound ; annotation
                     ; body = ppt_of_dkterm t ; b_args }
  | T.Pi(_,id,t,u) ->
    let annotation = Some(ppt_of_dkterm t) in
    let body = ppt_of_dkterm u in
    let bound = B.string_of_ident id in
    let b_args = List.map ppt_of_dkterm stk in
    Jt.Ppterm.Binder { b_symb = "Π" ; bound ; annotation ; body ; b_args }

let doc_of_entries : B.mident -> E.entry list -> Jt.item list =
  fun mdl entries ->
  let init = { ct_taxo = D.NameMap.empty
             ; ct_deps = D.NameMap.empty
             ; ct_thax = D.NameMap.empty }
  in
  let rec loop : content -> E.entry list -> Jt.item list = fun acc ens ->
    match ens with
    | []      -> []
    | e :: tl ->
      match e with
      | E.Decl(_,id,_,_)
      | E.Def(_,id,_,_,_) ->
        let inm = B.mk_name mdl id in
        let deps = Tx.find_deps mdl (Tx.New e) in
        let acc =
          let ct_deps = D.NameMap.add inm deps acc.ct_deps in
          { acc with ct_deps }
        in
        let deps =
          let fill n =
            U.of_dkname n Tx.Sttfa.theory
              (Tx.Sttfa.to_string ~short:true (find_taxon acc n))
          in
          List.map fill deps
        in
        begin match e with
          | E.Decl(_,id,_,t) ->
            let tx = Tx.Sttfa.of_decl t in
            let acc = { acc with ct_taxo = D.NameMap.add inm tx acc.ct_taxo } in
            let uri = U.of_dkname (B.mk_name mdl id) Tx.Sttfa.theory
                (Tx.Sttfa.to_string ~short:true tx) |> U.to_string
            in
            let ppt_body =  ppt_of_dkterm mdl acc t in
            { name = uri
            ; taxonomy = Tx.Sttfa.to_string tx
            ; term = None
            ; body = ppt_body
            ; deps = List.map U.to_string deps
            ; theory = []
            ; exp = [] } :: (loop acc tl)
          | E.Def(_,id,_,teo,te)  ->
            let tx = Tx.Sttfa.of_def te in
            let acc = { acc with ct_taxo = D.NameMap.add inm tx acc.ct_taxo } in
            let uri = U.of_dkname (B.mk_name mdl id) Tx.Sttfa.theory
                (Tx.Sttfa.to_string ~short:true tx) |> U.to_string
            in
            let ppt_body = ppt_of_dkterm mdl acc te in
            let ppt_term_opt = Option.map (ppt_of_dkterm mdl acc) teo in
            { name = uri
            ; taxonomy = Tx.Sttfa.to_string tx
            ; term = ppt_term_opt
            ; body = ppt_body
            ; deps = List.map U.to_string deps
            ; theory = []
            ; exp = [] } :: (loop acc tl)
          | _                     -> loop acc tl
        end
      | _ -> loop acc tl
  in
  loop init entries

let print_document : Format.formatter -> Jt.document -> unit = fun fmt doc ->
  Jt.document_to_yojson doc |> Yojson.Safe.pretty_print fmt
