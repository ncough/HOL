structure Cache :> Cache =
struct

open Exception Lib liteLib;
open Trace Termtable;

  type term = Term.term
  type thm = Thm.thm
  type conv = Abbrev.conv;

infix <<;  (* A subsetof B *)
fun x << y = all (C mem y) x;

type table = (term list * thm option) list termtable
type cache = table ref;

local exception NOT_FOUND
      exception FIRST
in
fun CACHE (filt,conv) =
  let fun first p [] = raise FIRST
        | first p (h::t) = if p h then h else first p t;
      val cache = (ref (mk_termtable (100,NOT_FOUND)): cache);
      fun cache_proc thms tm =
        let val _ = if (filt tm) then ()
                    else failwith "CACHE_CCONV: not applicable"
            val prevs = termtable_find (!cache) ([],tm) handle NOT_FOUND => []
            val curr = flatten (map Thm.hyp thms)
            fun ok (prev,SOME thm) = prev << curr
              | ok (prev,NONE) = curr << prev
        in (case (snd (first ok prevs)) of
              SOME x => (trace(1,PRODUCE(tm,"cache hit!",x)); x)
            | NONE => failwith "cache hit was failure")
          handle FIRST =>
          let val thm = conv thms tm
              handle e as (HOL_ERR _)
                 => (trace(2,REDUCE("Inserting failed ctxt",
                                    Dsyntax.mk_imp{ant =
                                                   Dsyntax.list_mk_conj curr,
                                                   conseq = tm}));
                     termtable_insert (!cache) (([],tm),(curr,NONE)::prevs);
                     raise e)
          in (trace(2,PRODUCE(tm, "Inserting into cache:", thm));
              termtable_insert (!cache) (([],tm),(curr,SOME thm)::prevs); thm)
          end
        end;
  in (cache_proc, cache)
  end

fun clear_cache cache = (cache := (mk_termtable (100,NOT_FOUND):table))
fun print_cache (cache:cache) = let
  val key_item_pairs = termtable_list (!cache)
  fun print_thmopt (SOME thm) = (print "SOME "; Parse.print_thm thm)
    | print_thmopt NONE = print "NONE"
  fun pr_list0 pfn [] = print "]"
    | pr_list0 pfn [x] = (pfn x; print "]")
    | pr_list0 pfn (x::xs) = (pfn x; print ", "; pr_list0 pfn xs)
  fun pr_list pfn l = (print "["; pr_list0 pfn l)
  fun pr_v (tml, thmopt) = (print "("; pr_list Parse.print_term tml;
                            print ", "; print_thmopt thmopt; print ")")
  fun pr_kv ((l, tm), vlist) = let
  in
    Parse.print_term tm; print " |-> ";
    pr_list pr_v vlist; print "\n"
  end
in
  app pr_kv key_item_pairs
end



end; (* local *)

end (* struct *)
