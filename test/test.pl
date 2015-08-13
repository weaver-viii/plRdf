:- ensure_loaded(debug).

%/ctriples
:- use_module(library(ctriples/ctriples_write_generics)).
:- use_module(library(ctriples/ctriples_write_graph)).
:- use_module(library(ctriples/ctriples_write_triples)).
%/dcg
:- use_module(library(dcg/langtag)).
:- use_module(library(dcg/langtag_char)).
:- use_module(library(dcg/rfc3987)).
:- use_module(library(dcg/sw_char)).
:- use_module(library(dcg/sw_iri)).
:- use_module(library(dcg/sw_literal)).
:- use_module(library(dcg/sw_number)).
:- use_module(library(dcg/sw_string)).
:- use_module(library(dcg/uri_authority)).
:- use_module(library(dcg/uri_fragment)).
:- use_module(library(dcg/uri_hier)).
:- use_module(library(dcg/uri_host)).
:- use_module(library(dcg/uri_port)).
:- use_module(library(dcg/uri_query)).
:- use_module(library(dcg/uri_relative)).
:- use_module(library(dcg/uri_scheme)).
%/html
:- use_module(library(html/rdf_html_meta)).
%/mat
:- use_module(library(mat/j_db)).
:- use_module(library(mat/mat)).
:- use_module(library(mat/mat_deb)).
%/owl
:- use_module(library(owl/owl_build)).
:- use_module(library(owl/owl_read)).
%/rdf
:- use_module(library(rdf/rdf_auth)).
:- use_module(library(rdf/rdf_bnode_name)).
:- use_module(library(rdf/rdf_build)).
:- use_module(library(rdf/rdf_container)).
:- use_module(library(rdf/rdf_datatype)).
:- use_module(library(rdf/rdf_default)).
:- use_module(library(rdf/rdf_graph)).
:- use_module(library(rdf/rdf_graph_nav)).
:- use_module(library(rdf/rdf_image)).
:- use_module(library(rdf/rdf_json_build)).
:- use_module(library(rdf/rdf_list)).
:- use_module(library(rdf/rdf_literal)).
:- use_module(library(rdf/rdf_prefix)).
:- use_module(library(rdf/rdf_print)).
:- use_module(library(rdf/rdf_read)).
:- use_module(library(rdf/rdf_term)).
:- use_module(library(rdf/rdf_update)).
%/rdfs
:- use_module(library(rdfs/rdfs_build)).
%/sparql
:- use_module(library(sparql/sparql_db)).
