:- module(
  rdf_guess_xml,
  [
    rdf_guess_xml/2 % +Snippet, -MT
  ]
).

/** <module> RDF guess: XML-family

@author Jan Wielemaker
@author Wouter Beek
@version 2015/12, 2016/06, 2016/11
*/

:- use_module(library(memfile)).
:- use_module(library(semweb/rdf11)).
:- use_module(library(sgml/sgml_ext)).
:- use_module(library(q/q_term)).





%! rdf_guess_xml(+Snippet, -MT) is det.

rdf_guess_xml(S, MT) :-
  setup_call_cleanup(
    new_memory_file(MFile),
    (
      setup_call_cleanup(
        open_memory_file(MFile, write, Write),
        format(Write, "~s", [S]),
        close(Write)
      ),
     setup_call_cleanup(
        open_memory_file(MFile, read, Read),
        guess_xml_type(Read, MT),
        close(Read)
      )
    ),
    free_memory_file(MFile)
  ).



%! guess_xml_type(+Read, -MT) is semidet.
%
% Try to see whether the document is some form of HTML or XML and in
% particular whether it is RDF/XML.  The latter is basically
% impossible because it is not obligatory for an RDF/XML document to
% have an rdf:RDF top level element, and when using a typed node, just
% about anything can qualify for RDF.  The only real demand is the XML
% document uses XML namespaces because these are both required to
% define <rdf:Description> and a valid type IRI from a typed node.
%
% If the toplevel element is detected as =HTML=, we pass =rdfa= as type.

guess_xml_type(Read, MT) :-
  xml_doctype(Read, Dialect, DocType, Attrs),
  doc_content_type(Dialect, DocType, Attrs, MT).



%! xml_doctype(+Read, -Dialect:atom, -DocType:atom, -Attrs) is semidet.
%
% Parse a _repositional_ stream and get the name of the first XML
% element *and* demand that this element defines XML namespaces.
% Fails if the document is illegal XML before the first element.
%
% Note that it is not possible to define valid RDF/XML without
% namespaces, while it is not possible to define a valid absolute
% Turtle IRI (using `<...>`-notation) with a valid xmlns declaration.

xml_doctype(Read, Dialect, DocType, Attrs) :-
  catch(
    sgml_parser(
      Read,
      sgml_parser0([
        call(begin, on_begin),
        call(cdata, on_cdata),
        max_errors(-1),
        source(Read),
        syntax_errors(quiet)
      ])
    ),
    E,
    true
  ),
  nonvar(E),
  E = tag(Dialect, DocType, Attrs).

sgml_parser0(Opts, Parser) :-
  sgml_parse(Parser, Opts).

on_begin(Tag, Attrs, Parser) :-
  get_sgml_parser(Parser, dialect(Dialect)),
  throw(tag(Dialect, Tag, Attrs)).

on_cdata(_, _) :-
  throw(error(cdata)).



%! doc_content_type(+Dialect, +Doctype, +Attrs, -MT) is det.

doc_content_type(_, html, _, text/html) :- !.
doc_content_type(html, _, _, text/html) :- !.
doc_content_type(xhtml, _, _, application/'xhtml+xml') :- !.
doc_content_type(html5, _, _, text/html) :- !.
doc_content_type(xhtml5, _, _, application/'xhtml+xml') :- !.
doc_content_type(xml, rss, _, application/'rss+xml') :- !.
doc_content_type(Dialect, Top,  Attrs, application/'xhtml+xml') :-
  % Extract the namespace from the doctype.
  (   Dialect == sgml
  ->  LocalName = rdf
  ;   Dialect == xml
  ->  LocalName = 'RDF'
  ),
  atomic_list_concat([NS,LocalName], :, Top),

  % Look up the RDF namespace in the attributes list.
  atomic_list_concat([xmlns,NS], :, Attr),
  memberchk(Attr=RDFNS, Attrs),

  % Ensure it is indeed the RDF namespace.
  q_alias_prefix(rdf, RDFNS).
