:- module(
  rdf_datatype,
  [
    rdf_canonical_map/3, % +Datatype:iri
                         % +Value
                         % ?LexicalForm:atom
    rdf_compare/4, % +Datatype:iri
                   % -Order:oneof([incomparable,<,=,>])
                   % +Value1
                   % +Value2
    rdf_datatype/1, % ?Datatype:iri
    rdf_datatype/2, % ?Datatype:iri
                    % ?PrologType
    rdf_datatype_term/1, % ?Datatype:iri
    rdf_datatype_term/2, % ?Datatype:iri
                         % ?Graph:atom
    rdf_equiv/3, % +Datatype:iri
                 % +Value1
                 % +Value2
    rdf_lexical_canonical_map/3, % +Datatype:iri
                                 % +LexicalForm:atom
                                 % ?CanonicalLexicalFrom:atom
    rdf_lexical_map/2, % +Literal:compound
                       % ?Value
    rdf_lexical_map/3, % +Datatype:iri
                       % +LexicalForm:atom
                       % ?Value
    rdf_subtype_of/2 % ?SubType:iri
                     % ?SuperType:iri
  ]
).

/** <module> RDF datatype

@author Wouter Beek
@compat [RDF 1.1 Concepts and Abstract Syntax](http://www.w3.org/TR/2014/REC-rdf11-concepts-20140225/)
@version 2015/07
*/

:- use_module(library(html/html_dom)).
:- use_module(library(memfile)).
:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/rdfs)).
:- use_module(library(sgml)).
:- use_module(library(sgml_write)).
:- use_module(library(xml/xml_dom)).
:- use_module(library(xsd/xsd)).
:- use_module(library(xsd/xsd_update)).

:- rdf_meta(rdf_canonical_map(r,+,?)).
:- rdf_meta(rdf_compare(r,?,+,+)).
:- rdf_meta(rdf_datatype(r)).
:- rdf_meta(rdf_datatype(r,?)).
:- rdf_meta(rdf_datatype_term(r)).
:- rdf_meta(rdf_datatype_term(r,?)).
:- rdf_meta(rdf_equiv(r,+,+)).
:- rdf_meta(rdf_lexical_canonical_map(r,+,?)).
:- rdf_meta(rdf_lexical_map(r,+,?)).
:- rdf_meta(rdf_subtype_of(r,r)).





%! rdf_canonical_map(+Datatype:iri, +Value, +LexicalForm:atom) is semidet.
%! rdf_canonical_map(+Datatype:iri, +Value, -LexicalForm:atom) is det.
% Maps RDF datatyped values onto a unique / canonical lexical form.
%
% Supports the following RDF datatypes:
%   - `rdf:HTML`
%   - `rdf:XMLLiteral`
%   - The XSD datatypes as defined by xsd.pl.
%
% @compat [RDF 1.1 Concepts and Abstract Syntax](http://www.w3.org/TR/2014/REC-rdf11-concepts-20140225/)

rdf_canonical_map(rdf:'HTML', Value, LexicalForm):- !,
  with_output_to(atom(LexicalForm), html_write(current_output, Value, [])).
rdf_canonical_map(rdf:'XMLLiteral', Value, LexicalForm):- !,
  with_output_to(atom(LexicalForm), xml_write(current_output, Value, [])).
rdf_canonical_map(Datatype, Value, LexicalForm):-
  xsd_canonical_map(Datatype, Value, LexicalForm).



%! rdf_compare(
%!   +Datatype:iri,
%!   +Order:oneof([incomparable,<,=,>]),
%!   +Value1,
%!   +Value2
%! ) is semidet.
%! rdf_compare(
%!   +Datatype:iri,
%!   -Order:oneof([incomparable,<,=,>]),
%!   +Value1,
%!   +Value2
%! ) is semidet.

rdf_compare(D, Order, V1, V2):-
  (   rdf_equal(D, rdf:'HTML')
  ;   rdf_equal(D, rdf:'XMLLiteral')
  ), !,
  compare(Order, V1, V2).
rdf_compare(D, Order, V1, V2):-
  xsd_compare(D, Order, V1, V2).



%! rdf_datatype(+Datatype:iri) is semidet.
%! rdf_datatype(-Datatype:iri) is multi.

rdf_datatype(D):-
  rdf_datatype(D, _).

%! rdf_datatype(+Datatype:iri, +PrologType) is semidet.
%! rdf_datatype(+Datatype:iri, -PrologType) is det.
%! rdf_datatype(-Datatype:iri, +PrologType) is nondet.
%! rdf_datatype(-Datatype:iri, -PrologType) is nondet.

rdf_datatype(rdf:'HTML', compound).
rdf_datatype(rdf:'XMLLiteral', compound).
rdf_datatype(rdf:langString, pair).
rdf_datatype(D, Type):-
  xsd_datatype(D, Type).



%! rdf_datatype_term(+Datatype:iri) is semidet.
%! rdf_datatype_term(-Datatype:iri) is nondet.

rdf_datatype_term(D):-
  rdf_datatype_term(D, _).

%! rdf_datatype_term(+Datatype:iri, +Graph:atom) is semidet.
%! rdf_datatype_term(+Datatype:iri, -Graph:atom) is nondet.
%! rdf_datatype_term(-Datatype:iri, +Graph:atom) is nondet.
%! rdf_datatype_term(-Datatype:iri, -Graph:atom) is nondet.

rdf_datatype_term(D, G):-
  rdf(_, _, literal(type(D,_)), G).
rdf_datatype_term(D, G):-
  rdfs_individual_of(D, rdfs:'Datatype'),
  rdf_term(D, G).



%! rdf_equiv(+Datatype:iri, +Value1, +Value2) is semidet.
% RDF typed literal value equivalence w.r.t. a datatype.

rdf_equiv(D, V1, V2):-
  rdf_compare(D, =, V1, V2).



%! rdf_lexical_canonical_map(
%!   +Datatype:iri,
%!   +LexicalForm:atom,
%!   -CanonicalLexicalFrom:atom
%! ) is det.

rdf_lexical_canonical_map(D, Lex, CLex):-
  xsd_lexical_canonical_map(D, Lex, CLex).



%! rdf_lexical_map(+Literal:compound, +Value) is semidet.
%! rdf_lexical_map(+Literal:compound, -Value) is det.

% Typed literal (as per RDF 1.0 specification).
rdf_lexical_map(literal(type(D,LexicalForm)), V):- !,
  rdf_lexical_map(D, LexicalForm, V).
% Language-tagged string.
rdf_lexical_map(literal(lang(LangTag,LexicalForm)), LangTag-LexicalForm):- !.
% Simple literal (as per RDF 1.0 specification)
% now assumed to be of type `xsd:string` (as per RDF 1.1 specification).
rdf_lexical_map(literal(LexicalForm), V):-
  rdf_lexical_map(xsd:string, LexicalForm, V).



%! rdf_lexical_map(+Datatype:iri, +LexicalForm:atom, +Value) is semidet.
%! rdf_lexical_map(+Datatype:iri, +LexicalForm:atom, -Value) is det.
% Maps lexical forms onto the values they represent.
%
% Supports the following RDF datatypes:
%   - `rdf:HTML`
%   - `rdf:XMLLiteral`
%   - The XSD datatypes as defined by xsd.pl.
%
% @compat [RDF 1.1 Concepts and Abstract Syntax](http://www.w3.org/TR/2014/REC-rdf11-concepts-20140225/)

rdf_lexical_map(rdf:'HTML', LexicalForm, V):- !,
  atom_to_html_dom(LexicalForm, V).
rdf_lexical_map(rdf:'XMLLiteral', LexicalForm, V):- !,
  atom_to_xml_dom(LexicalForm, V).
rdf_lexical_map(D, LexicalForm, V):-
  xsd_lexical_map(D, LexicalForm, V).



%! rdf_subtype_of(+Subtype:iri, +Supertype:iri) is semidet.
%! rdf_subtype_of(+Subtype:iri, -Supertype:iri) is nondet.
%! rdf_subtype_of(-Subtype:iri, +Supertype:iri) is nondet.
%! rdf_subtype_of(-Subtype:iri, -Supertype:iri) is multi.

rdf_subtype_of(X, Y):-
  rdfs_subclass_of(X, Y).
rdf_subtype_of(X, Y):-
  xsd_subtype_of(X, Y).