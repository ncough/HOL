(*****************************************************************************)
(* Create "ExecuteSemantics": a derived fixpoint-style executable semantics  *)
(*                                                                           *)
(* Created Wed Mar 19 19:01:20 GMT 2003                                      *)
(*****************************************************************************)

(*****************************************************************************)
(* START BOILERPLATE                                                         *)
(*****************************************************************************)

(******************************************************************************
* Load theories
* (commented out for compilation)
* Compile using "Holmake -I ../official-semantics -I ../regexp"
******************************************************************************)
(* 
loadPath := "../official-semantics" :: "../regexp" :: !loadPath;
app load ["bossLib","metisLib","intLib","res_quanTools","pred_setLib",
          "PropertiesTheory", "regexpLib"];
*)

(******************************************************************************
* Boilerplate needed for compilation
******************************************************************************)
open HolKernel Parse boolLib;

(******************************************************************************
* Open theories (comment out quietdec's for compilation)
******************************************************************************)

(* 
quietdec := true;
*)

open bossLib metisLib rich_listTheory pred_setLib intLib;
open regexpTheory matcherTheory;
open FinitePathTheory PathTheory UnclockedSemanticsTheory
     ClockedSemanticsTheory PropertiesTheory

(* 
quietdec := false;
*)

(******************************************************************************
* Set default parsing to natural numbers rather than integers 
******************************************************************************)
val _ = intLib.deprecate_int();

(*****************************************************************************)
(* END BOILERPLATE                                                           *)
(*****************************************************************************)

(******************************************************************************
* A simpset fragment to rewrite away quantifiers restricted with :: (a to b)
******************************************************************************)
val resq_SS = 
 simpLib.merge_ss
  [res_quanTools.resq_SS,
   rewrites
    [num_to_def,xnum_to_def,IN_DEF,num_to_def,xnum_to_def,LENGTH_def]];

val arith_resq_ss = simpLib.++ (arith_ss, resq_SS);
val list_resq_ss  = simpLib.++ (list_ss,  resq_SS);

(*---------------------------------------------------------------------------*)
(* Symbolic tacticals.                                                       *)
(*---------------------------------------------------------------------------*)

infixr 0 ++ << || THENC ORELSEC ORELSER ##;
infix 1 >>;

val op ++ = op THEN;
val op << = op THENL;
val op >> = op THEN1;
val op || = op ORELSE;
val Know = Q_TAC KNOW_TAC;
val Suff = Q_TAC SUFF_TAC;
val REVERSE = Tactical.REVERSE;

val pureDefine = with_flag (computeLib.auto_import_definitions, false) Define;

(******************************************************************************
* Start a new theory called "ExecuteSemantics"
******************************************************************************)
val _ = new_theory "ExecuteSemantics";

(******************************************************************************
* Boolean expression SEREs representing truth and falsity
******************************************************************************)
val S_TRUE_def  = Define `S_TRUE  = S_BOOL B_TRUE`;
val S_FALSE_def = Define `S_FALSE = S_BOOL B_FALSE`;

(******************************************************************************
* Executable semantics of [f1 U f2]
*   w |= [f1 U f2] 
*   <==> 
*   |w| > 0 And (w |= f2  Or  (w |= f1  And  w^1 |= [f1 U f2]))
******************************************************************************)
val UF_SEM_F_UNTIL_REC =
 store_thm
  ("UF_SEM_F_UNTIL_REC",
   ``UF_SEM w (F_UNTIL(f1,f2)) = 
      LENGTH w > 0
      /\
      (UF_SEM w f2
       \/
       (UF_SEM w f1 /\ UF_SEM (RESTN w 1) (F_UNTIL(f1,f2))))``,
   RW_TAC arith_resq_ss [UF_SEM_def]
    THEN Cases_on `w`
    THEN ONCE_REWRITE_TAC[arithmeticTheory.ONE]
    THEN RW_TAC arith_resq_ss
         [num_to_def,xnum_to_def,RESTN_def,REST_def,LENGTH_def]
    THEN EQ_TAC
    THEN RW_TAC arith_ss [GT]
    THENL
     [DECIDE_TAC,
      Cases_on `UF_SEM (FINITE l) f2`
       THEN RW_TAC std_ss []
       THEN Cases_on `k=0`
       THEN RW_TAC arith_ss []
       THEN FULL_SIMP_TAC std_ss [RESTN_def]
       THEN `0 < k` by DECIDE_TAC
       THEN RES_TAC
       THENL
        [PROVE_TAC[RESTN_def],
         `k - 1 < LENGTH l - 1` by DECIDE_TAC
          THEN Q.EXISTS_TAC `k-1`
          THEN RW_TAC arith_ss [LENGTH_TL]
          THENL
           [`k = SUC(k-1)` by DECIDE_TAC
             THEN ASSUM_LIST(fn thl => ASSUME_TAC(SUBS[el 1 thl] (el 8 thl)))
             THEN FULL_SIMP_TAC std_ss [RESTN_def,REST_def],
            `SUC j < k` by DECIDE_TAC
             THEN RES_TAC
             THEN FULL_SIMP_TAC std_ss [REST_def, RESTN_def]]],
      Q.EXISTS_TAC `0`
       THEN RW_TAC arith_ss [RESTN_def],
      `LENGTH (TL l) = LENGTH l - 1` by RW_TAC arith_ss [LENGTH_TL]
        THEN `SUC k < LENGTH l` by DECIDE_TAC
        THEN Q.EXISTS_TAC `SUC k`
        THEN RW_TAC std_ss [RESTN_def,REST_def]
        THEN Cases_on `j=0`
        THEN RW_TAC std_ss [RESTN_def]
        THEN `j - 1 < k` by DECIDE_TAC
        THEN RES_TAC
        THEN `j = SUC(j-1)` by DECIDE_TAC
        THEN POP_ASSUM(fn th => SUBST_TAC[th])
        THEN RW_TAC std_ss [RESTN_def,REST_def],
      Cases_on `UF_SEM (INFINITE f) f2`
       THEN RW_TAC std_ss []
       THEN Cases_on `k=0`
       THEN RW_TAC arith_ss []
       THEN FULL_SIMP_TAC std_ss [RESTN_def]
       THEN `0 < k` by DECIDE_TAC
       THEN RES_TAC
       THEN FULL_SIMP_TAC std_ss [RESTN_def,GSYM REST_def]
       THEN `k = SUC(k-1)` by DECIDE_TAC
       THEN ASSUM_LIST(fn thl => ASSUME_TAC(SUBS[el 1 thl] (el 7 thl)))
       THEN FULL_SIMP_TAC std_ss [RESTN_def]
       THEN Q.EXISTS_TAC `k-1`
       THEN RW_TAC std_ss []
       THEN `SUC j < k` by DECIDE_TAC
       THEN PROVE_TAC[RESTN_def],
      Q.EXISTS_TAC `0`
       THEN RW_TAC arith_ss [RESTN_def],
      Q.EXISTS_TAC `SUC k`
       THEN FULL_SIMP_TAC std_ss [GSYM REST_def]
       THEN RW_TAC std_ss [RESTN_def]
       THEN Cases_on `j=0`
       THEN RW_TAC std_ss [RESTN_def]
       THEN `j - 1 < k` by DECIDE_TAC
       THEN RES_TAC
       THEN `j = SUC(j-1)` by DECIDE_TAC
       THEN POP_ASSUM(fn th => SUBST_TAC[th])
       THEN RW_TAC std_ss [RESTN_def]]);

(******************************************************************************
* Executable semantics of {r}(f) on finite paths.
*
* First define w |=_n f
*
*   w |=_0 {r}(f)
*
*   w |=_{n+1} {r}(f)  
*   <==>  
*   w |=_n {r}(f)  And  (w^{0,n} |= r  Implies  w^n |= f)
*
* then
*
*   w |= {r}(f)  <==>  w |=_|w| {r}(f)
******************************************************************************)
val UF_SEM_F_SUFFIX_IMP_FINITE_REC_def =
 Define 
  `(UF_SEM_F_SUFFIX_IMP_FINITE_REC w (r,f) 0 = T)
   /\
   (UF_SEM_F_SUFFIX_IMP_FINITE_REC w (r,f) (SUC n) = 
     UF_SEM_F_SUFFIX_IMP_FINITE_REC w (r,f) n
     /\ 
     (US_SEM (SEL w (0, n)) r ==> UF_SEM (RESTN w n) f))`;

(******************************************************************************
* Form needed for computeLib.EVAL
******************************************************************************)
val UF_SEM_F_SUFFIX_IMP_FINITE_REC_AUX =
 store_thm
  ("UF_SEM_F_SUFFIX_IMP_FINITE_REC_AUX",
  ``UF_SEM_F_SUFFIX_IMP_FINITE_REC w (r,f) n = 
     (n = 0) \/
     (UF_SEM_F_SUFFIX_IMP_FINITE_REC w (r,f) (n-1)
      /\ 
     (US_SEM (SEL w (0, (n-1))) r ==> UF_SEM (RESTN w (n-1)) f))``,
  Cases_on `n`
   THEN RW_TAC arith_ss [UF_SEM_F_SUFFIX_IMP_FINITE_REC_def]);

(******************************************************************************
* UF_SEM_F_SUFFIX_IMP_FINITE_REC_FORALL
*
*  (All j < n: w^{0,j} |= r Implies w^j |= f) = w |=_n {r}(f)
******************************************************************************)
local
val UF_SEM_F_SUFFIX_IMP_FINITE_REC_FORALL1 =
 prove
  (``(!j. j < n ==> US_SEM (SEL w (0,j)) r ==> UF_SEM (RESTN w j) f)
     ==>
     UF_SEM_F_SUFFIX_IMP_FINITE_REC w (r,f) n``,
   Induct_on `n`
    THEN RW_TAC arith_ss [UF_SEM_F_SUFFIX_IMP_FINITE_REC_def]);

val UF_SEM_F_SUFFIX_IMP_FINITE_REC_FORALL2 =
 prove
  (``UF_SEM_F_SUFFIX_IMP_FINITE_REC w (r,f) n
     ==>
     (!j. j < n ==> US_SEM (SEL w (0,j)) r ==> UF_SEM (RESTN w j) f)``,
   Induct_on `n`
    THEN RW_TAC arith_ss [UF_SEM_F_SUFFIX_IMP_FINITE_REC_def]
    THEN Cases_on `j=n`
    THEN RW_TAC std_ss []
    THEN `j < n` by DECIDE_TAC
    THEN PROVE_TAC[]);
in
val UF_SEM_F_SUFFIX_IMP_FINITE_REC_FORALL =
 store_thm
  ("UF_SEM_F_SUFFIX_IMP_FINITE_REC_FORALL",
   ``(!j. j < n ==> US_SEM (SEL w (0,j)) r ==> UF_SEM (RESTN w j) f)
     =
     UF_SEM_F_SUFFIX_IMP_FINITE_REC w (r,f) n``,
   PROVE_TAC[UF_SEM_F_SUFFIX_IMP_FINITE_REC_FORALL1,UF_SEM_F_SUFFIX_IMP_FINITE_REC_FORALL2]);
end;

(******************************************************************************
* w |= {r}(f)  <==>  w |=_|w| {r}(f)
******************************************************************************)
val UF_SEM_F_SUFFIX_IMP_FINITE_REC =
 store_thm
  ("UF_SEM_F_SUFFIX_IMP_FINITE_REC",
   ``UF_SEM (FINITE w) (F_SUFFIX_IMP(r,f)) = 
      UF_SEM_F_SUFFIX_IMP_FINITE_REC (FINITE w) (r,f) (LENGTH w)``,
   RW_TAC list_resq_ss [UF_SEM_def]
    THEN PROVE_TAC[UF_SEM_F_SUFFIX_IMP_FINITE_REC_FORALL]);

(******************************************************************************
* Define w |=_x {r}(f) where x is an extended number (xnum)
******************************************************************************)
val UF_SEM_F_SUFFIX_IMP_REC_def =
 Define 
  `(UF_SEM_F_SUFFIX_IMP_REC w (r,f) (XNUM n) = 
     UF_SEM_F_SUFFIX_IMP_FINITE_REC w (r,f) n)
   /\
   (UF_SEM_F_SUFFIX_IMP_REC w (r,f) INFINITY = 
     !n. US_SEM (SEL w (0,n)) r ==> UF_SEM (RESTN w n) f)`;

(******************************************************************************
* w |= {r}(f)  <==>  w |=_|w| {r}(f)  (for finite and infinite paths w)
******************************************************************************)
val UF_SEM_F_SUFFIX_IMP_REC =
 store_thm
  ("UF_SEM_F_SUFFIX_IMP_REC",
   ``UF_SEM w (F_SUFFIX_IMP(r,f)) = 
      UF_SEM_F_SUFFIX_IMP_REC w (r,f) (LENGTH w)``,
   Cases_on `w`
    THEN RW_TAC list_resq_ss
          [UF_SEM_def,UF_SEM_F_SUFFIX_IMP_FINITE_REC,
           UF_SEM_F_SUFFIX_IMP_REC_def]);

(*---------------------------------------------------------------------------*)
(* Converting regexps from SyntaxTheory to regexpTheory.                     *)
(*---------------------------------------------------------------------------*)

val CONCAT_is_CONCAT = prove
  (``FinitePath$CONCAT = regexp$CONCAT``,
   RW_TAC std_ss [FUN_EQ_THM]
   ++ Induct_on `x`
   ++ RW_TAC std_ss [FinitePathTheory.CONCAT_def, regexpTheory.CONCAT_def]);

val unclocked_def = Define
  `(unclocked (S_BOOL b) = T) /\
   (unclocked (S_CAT (r1, r2)) = unclocked r1 /\ unclocked r2) /\
   (unclocked (S_FUSION (r1, r2)) = unclocked r1 /\ unclocked r2) /\
   (unclocked (S_OR (r1, r2)) = unclocked r1 /\ unclocked r2) /\
   (unclocked (S_AND (r1, r2)) = unclocked r1 /\ unclocked r2) /\
   (unclocked (S_REPEAT r) = unclocked r) /\
   (unclocked (S_CLOCK (r, b)) = F)`;

val sere2regexp_def = Define
  `(sere2regexp (S_BOOL b) = Atom (\l. B_SEM l b)) /\
   (sere2regexp (S_CAT (r1, r2)) = Cat (sere2regexp r1) (sere2regexp r2)) /\
   (sere2regexp (S_FUSION (r1, r2)) = Fuse (sere2regexp r1) (sere2regexp r2)) /\
   (sere2regexp (S_OR (r1, r2)) = Or (sere2regexp r1) (sere2regexp r2)) /\
   (sere2regexp (S_AND (r1, r2)) = And (sere2regexp r1) (sere2regexp r2)) /\
   (sere2regexp (S_REPEAT r) = Repeat (sere2regexp r))`;

val sere2regexp = prove
  (``!r l. unclocked r ==> (US_SEM l r = amatch (sere2regexp r) l)``,
   SIMP_TAC std_ss [amatch]
   ++ INDUCT_THEN sere_induct ASSUME_TAC
   ++ RW_TAC std_ss
      [US_SEM_def, sem_def, sere2regexp_def, ELEM_EL, EL, unclocked_def]
   ++ CONV_TAC (DEPTH_CONV ETA_CONV)
   ++ RW_TAC std_ss [CONCAT_is_CONCAT]);

val EVAL_US_SEM = store_thm
  ("EVAL_US_SEM",
   ``!l r.
       US_SEM l r =
       if unclocked r then amatch (sere2regexp r) l else US_SEM l r``,
   RW_TAC std_ss [GSYM sere2regexp]);

(* Some examples of using EVAL
val _ = computeLib.add_funs 
         ([SEL_REC_AUX,
           UF_SEM_F_UNTIL_REC ,
           UF_SEM_F_SUFFIX_IMP_FINITE_REC_AUX,
           UF_SEM_F_SUFFIX_IMP_FINITE_REC(*,
           UF_SEM_F_SUFFIX_IMP_REC*)]
          @
          CONJUNCTS B_SEM
          @
          [(*EVAL_US_SEM*)]);

val _ = 
 computeLib.add_convs
  [(``$IN``,
    2,
    (pred_setLib.SET_SPEC_CONV ORELSEC pred_setLib.IN_CONV EVAL))];

EVAL ``UF_SEM (FINITE[s0;s1;s2]) (F_UNTIL(f1,f2))``;
EVAL ``UF_SEM (FINITE[s0;s1;s2]) (F_UNTIL(F_BOOL b1, F_BOOL b2))``;
EVAL ``UF_SEM (FINITE[s0;s1;s2]) (F_UNTIL(F_BOOL(B_PROP p1), F_BOOL(B_PROP p2)))``;
EVAL ``UF_SEM (FINITE[s0;s1;s2]) (F_UNTIL(F_BOOL(B_PROP 1), F_BOOL(B_PROP 2)))``;
EVAL ``UF_SEM (FINITE[{1};{1};{2}]) (F_UNTIL(F_BOOL(B_PROP 1), F_BOOL(B_PROP 2)))``;
EVAL ``UF_SEM (FINITE[{1};{3};{2}]) (F_UNTIL(F_BOOL(B_PROP 1), F_BOOL(B_PROP 2)))``;

(* Can't evaluate a variable regular expression
EVAL ``UF_SEM (FINITE[s0;s1;s2]) (F_SUFFIX_IMP(r,f))``;
*)

EVAL ``UF_SEM (FINITE[{1};{3};{2}])
       (F_SUFFIX_IMP (S_BOOL (B_PROP n), f))``;

EVAL ``UF_SEM (FINITE[{1};{3};{2}]) (F_UNTIL(F_BOOL(B_PROP 1), F_BOOL(B_PROP 2)))``;
*)

val _ = export_theory();
