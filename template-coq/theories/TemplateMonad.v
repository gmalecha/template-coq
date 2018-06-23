From Coq Require Import Strings.String.
From Template Require Import Ast.
From Template Require Import monad_utils.

(** ** The Template Monad

  A monad for programming with Template Coq structures. *)

(** Reduction strategy to apply, beware [cbv], [cbn] and [lazy] are _strong_. *)

Inductive reductionStrategy : Set :=
  cbv | cbn | hnf | all | lazy.

Definition typed_term := {T : Type & T}.
Definition existT_typed_term a t : typed_term := @existT Type (fun T => T) a t.

Definition my_projT1 (t : typed_term) : Type := @projT1 Type (fun T => T) t.
Definition my_projT2 (t : typed_term) : my_projT1 t := @projT2 Type (fun T => T) t.

(** *** The TemplateMonad type *)

Inductive TemplateMonad : Type -> Prop :=
(* Monadic operations *)
| tmReturn : forall {A:Type}, A -> TemplateMonad A
| tmBind : forall {A B : Type}, TemplateMonad A -> (A -> TemplateMonad B)
                           -> TemplateMonad B

(* General commands *)
| tmPrint : forall {A:Type}, A -> TemplateMonad unit
| tmFail : forall {A:Type}, string -> TemplateMonad A
| tmEval : reductionStrategy -> forall {A:Type}, A -> TemplateMonad A

(* Return the defined constant *)
| tmDefinition : ident -> forall {A:Type}, A -> TemplateMonad A
| tmAxiom : ident -> forall A, TemplateMonad A
| tmLemma : ident -> forall A, TemplateMonad A

(* Guaranteed to not cause "... already declared" error *)
| tmFreshName : ident -> TemplateMonad ident

| tmAbout : ident -> TemplateMonad (option global_reference)
| tmCurrentModPath : unit -> TemplateMonad string

(* Quoting and unquoting commands *)
(* Similar to Quote Definition ... := ... *)
| tmQuote : forall {A:Type}, A  -> TemplateMonad term
(* Similar to Quote Recursively Definition ... := ...*)
| tmQuoteRec : forall {A:Type}, A  -> TemplateMonad program
(* Quote the body of a definition or inductive. Its name need not be fully qualified *)
| tmQuoteInductive : kername -> TemplateMonad mutual_inductive_body
| tmQuoteUniverses : unit -> TemplateMonad uGraph.t
| tmQuoteConstant : kername -> bool (* bypass opacity? *) -> TemplateMonad constant_entry
| tmMkDefinition : ident -> term -> TemplateMonad unit
    (* unquote before making the definition *)
    (* FIXME take an optional universe context as well *)
| tmMkInductive : mutual_inductive_entry -> TemplateMonad unit
| tmUnquote : term  -> TemplateMonad typed_term
| tmUnquoteTyped : forall A, term -> TemplateMonad A

(* Not yet implemented *)
| tmExistingInstance : ident -> TemplateMonad unit
.

(** This allow to use notations of MonadNotation *)

Instance TemplateMonad_Monad : Monad TemplateMonad :=
  {| ret := @tmReturn ; bind := @tmBind |}.
