SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 160
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 10000
set serveroutput on

-------------------------------- 

-- This example shows how to load an RDF graph based on RDF, RDFS, and OWL
-- standards into Oracle AI Database and query it with SPARQL wrapped in SQL.
-- 

-- Connect to the database, these examples use a database user named rdfuser

-- Create an RDF network.  This can contain many RDF graphs.  (Note that a database can also contain many RDF networks.)
EXECUTE SEM_APIS.CREATE_RDF_NETWORK('<tablespace_name>', network_owner => 'RDFUSER', network_name => 'RDF_NETWORK');

-- Create an RDF graph.  Graph name is 'university', database username is 'RDFUSER' and RDF network name is 'RDF_NETWORK'
EXECUTE SEM_APIS.CREATE_RDF_GRAPH('university', 'null', 'null', network_owner => 'RDFUSER', network_name => 'RDF_NETWORK');

-- Load an Ontology (TBox).  We will use the SEM_APIS.UPDATE_RDF_GRAPH API
BEGIN
  SEM_APIS.UPDATE_RDF_GRAPH('university',
   'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX  owl: <http://www.w3.org/2002/07/owl#>
    PREFIX univ: <http://univ.org#>

    INSERT DATA {

      univ:Person            rdf:type owl:Class .
      univ:Student           rdf:type owl:Class .
      univ:TakesAICourse     rdf:type owl:Class .
      univ:TakesStatsCourse  rdf:type owl:Class .
      univ:AIMajor           rdf:type owl:Class .
      univ:Instructor        rdf:type owl:Class .
      univ:Professor         rdf:type owl:Class .
      univ:Course            rdf:type owl:Class .
      univ:AICourse          rdf:type owl:Class .
      univ:StatisticsCourse  rdf:type owl:Class .
      univ:University        rdf:type owl:Class .

      univ:Student          rdfs:subClassOf univ:Person .
      univ:TakesAICourse    rdfs:subClassOf univ:Student .
      univ:TakesStatsCourse rdfs:subClassOf univ:Student .
      univ:AIMajor          rdfs:subClassOf univ:Student .
      univ:Instructor       rdfs:subClassOf univ:Person .
      univ:Professor        rdfs:subClassOf univ:Instructor .
      univ:AICourse         rdfs:subClassOf univ:Course .
      univ:StatisticsCourse rdfs:subClassOf univ:Course .

      univ:takes        rdf:type owl:ObjectProperty .
      univ:takes        rdfs:domain univ:Student .
      univ:takes        rdfs:range  univ:Course .

      univ:teaches      rdf:type owl:ObjectProperty .
      univ:teaches      rdfs:domain univ:Instructor .
      univ:teaches      rdfs:range  univ:Course .

      univ:isFullTimeAt rdf:type owl:ObjectProperty .
      univ:isFullTimeAt rdfs:domain univ:Professor .
      univ:isFullTimeAt rdfs:range  univ:University .

      univ:offers       rdf:type owl:ObjectProperty .
      univ:offers       rdfs:domain univ:University .
      univ:offers       rdfs:range  univ:Course .

      univ:name         rdf:type owl:DatatypeProperty .

      univ:AIMajor owl:equivalentClass _:aimajor .
      _:aimajor owl:intersectionOf _:int2 .
      _:int2 rdf:first _:taic_R .
      _:int2 rdf:rest  _:int3 .
      _:int3 rdf:first _:tscs_R .
      _:int3 rdf:rest  rdf:nil .
      _:taic_R owl:onProperty     univ:takes .
      _:taic_R owl:someValuesFrom univ:AICourse .
      _:tscs_R owl:onProperty     univ:takes .
      _:tscs_R owl:someValuesFrom univ:StatisticsCourse .

    }',
    network_owner => 'RDFUSER',
    network_name  => 'RDF_NETWORK');
END;
/

COMMIT;


--  Insert instance data (ABox) into the same RDF graph
BEGIN
  SEM_APIS.UPDATE_RDF_GRAPH('university',
   'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX univ: <http://univ.org#>

    INSERT DATA {

      univ:MIT rdf:type univ:University .
      univ:MIT univ:name "MIT" .

      univ:courseCS101   rdf:type univ:Course .
      univ:courseCS101   univ:name "Intro to Programming" .

      univ:courseCS601   rdf:type univ:Course .
      univ:courseCS601   univ:name "Advanced AI" .

      univ:courseSTAT201 rdf:type univ:StatisticsCourse .
      univ:courseSTAT201 univ:name "Applied Statistics" .

      univ:MIT univ:offers univ:courseCS101 .
      univ:MIT univ:offers univ:courseCS601 .
      univ:MIT univ:offers univ:courseSTAT201 .

      univ:alice univ:name "Alice" .
      univ:alice univ:takes univ:courseCS601 .
      univ:alice univ:takes univ:courseSTAT201 .

      univ:bob univ:name "Bob" .
      univ:bob univ:takes univ:courseCS101 .

      univ:carol univ:name "Carol" .
      univ:carol univ:takes univ:courseCS601 .

      univ:profA univ:name "Prof. A" .
      univ:profA univ:teaches      univ:courseCS601 .
      univ:profA univ:isFullTimeAt univ:MIT .

      univ:drB univ:name "Dr. B" .
      univ:drB univ:teaches univ:courseCS101 .

    }',
    network_owner => 'RDFUSER',
    network_name  => 'RDF_NETWORK');
END;
/

COMMIT;

-- Run some queries using SEM_MATCH. With the SEM_MATCH table function you can wrap a SPARQL query in SQL, so that you can run the query in any SQL tool
-- Q0: Find all entities of type Course.  CS101 and CS601 (from the ABox) are of type Course.
SELECT s$rdfterm AS entity
  FROM TABLE(SEM_MATCH(
    'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
     PREFIX univ: <http://univ.org#>
     SELECT ?s 
     WHERE { ?s rdf:type univ:Course .
             FILTER(STRSTARTS(STR(?s), "http://univ.org#"))}',
    SEM_Models('university'),
    null,
    null, null, null,
    ' PLUS_RDFT=VC ',
    null, null,
    'RDFUSER', 'RDF_NETWORK'))
ORDER BY s$rdfterm;

-- Q0.1: Find all entities of type AICourse.   Zero rows are returned, because there are no courses classified as an AICourse.
SELECT s$rdfterm AS entity
  FROM TABLE(SEM_MATCH(
    'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
     PREFIX univ: <http://univ.org#>
     SELECT ?s 
     WHERE { ?s rdf:type univ:AICourse .
             FILTER(STRSTARTS(STR(?s), "http://univ.org#"))}',
    SEM_Models('university'),
    null,
    null, null, null,
    ' PLUS_RDFT=VC ',
    null, null,
    'RDFUSER', 'RDF_NETWORK'))
ORDER BY s$rdfterm;

-- Add a new fact (ABox triple) to the RDF graph to classify CS601 as AICourse
BEGIN
  SEM_APIS.UPDATE_RDF_GRAPH('university',
   'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX univ: <http://univ.org#>
    INSERT DATA {
      univ:courseCS601 rdf:type univ:AICourse .
    }',
    network_owner => 'RDFUSER',
    network_name  => 'RDF_NETWORK');
END;
/

COMMIT;

-- Now run Q0.1 again: Find all entities of type AICourse.  You will find CS601 is now listed.
SELECT s$rdfterm AS entity
  FROM TABLE(SEM_MATCH(
    'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
     PREFIX univ: <http://univ.org#>
     SELECT ?s 
     WHERE { ?s rdf:type univ:AICourse .
             FILTER(STRSTARTS(STR(?s), "http://univ.org#"))}',
    SEM_Models('university'),
    null,
    null, null, null,
    ' PLUS_RDFT=VC ',
    null, null,
    'RDFUSER', 'RDF_NETWORK'))
ORDER BY s$rdfterm;

-- So far we have found facts stored in the RDF graph that already exist in the RDF graph.  For example CS601 is a Course and also an AICourse.

-- Now we will use some OWL rules to create new facts in our RDF graph. This process is known as inference or entailment.  In this example we use
-- the OWL2RL rule set

BEGIN
  SEM_APIS.CREATE_INFERRED_GRAPH(
    'univ_inf',
    SEM_Models('university'),
    SEM_Rulebases('OWL2RL'),
    0,
    '',
    '',
    network_owner => 'RDFUSER',
    network_name  => 'RDF_NETWORK');
END;
/

COMMIT;


-- Now let us run some queries that use the new triples that have been inferred in the inferencing step. 

-- Q1: Find inferred types for every Course.  You will find that more results returned, because the inference step has helped classify more entities as type Course
-- In additon to CS601 and CS101, now STAT201 is returned.  STAT201 had not been classified as a course, it had only been classified as a StatisticsCourse.  
-- StatisticsCourse had been defined as a sub class of Course.  With inferencing we derive that STAT201 rdf:type StatisticsCourse, StatisticsCourse rdfs:subClassOf Course,
-- so STAT201 rdf:type Course
SELECT s$rdfterm AS entity, type$rdfterm AS inferred_type
  FROM TABLE(SEM_MATCH(
    'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
     PREFIX univ: <http://univ.org#>
     SELECT ?s ?type
     WHERE { ?s rdf:type univ:Course .
             ?s rdf:type ?type .
             FILTER(STRSTARTS(STR(?type), "http://univ.org#")) }',
    SEM_Models('university'),
    SEM_Rulebases('OWL2RL'),
    null, null, null,
    ' PLUS_RDFT=VC ',
    null, null,
    'RDFUSER', 'RDF_NETWORK'))
ORDER BY s$rdfterm, type$rdfterm;

SELECT s$rdfterm AS entity, type$rdfterm AS inferred_type
  FROM TABLE(SEM_MATCH(
    'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
     PREFIX univ: <http://univ.org#>
     SELECT ?s ?type
     WHERE { ?s rdf:type univ:AICourse .
             ?s rdf:type ?type .
             FILTER(STRSTARTS(STR(?type), "http://univ.org#")) }',
    SEM_Models('university'),
    SEM_Rulebases('OWL2RL'),
    null, null, null,
    ' PLUS_RDFT=VC ',
    null, null,
    'RDFUSER', 'RDF_NETWORK'))
ORDER BY s$rdfterm, type$rdfterm;

-- Q1.1: Find all inferred types for every Person
SELECT s$rdfterm AS entity, type$rdfterm AS inferred_type
  FROM TABLE(SEM_MATCH(
    'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
     PREFIX univ: <http://univ.org#>
     SELECT ?s ?type
     WHERE { ?s rdf:type univ:Person .
             ?s rdf:type ?type .
             FILTER(STRSTARTS(STR(?type), "http://univ.org#")) }',
    SEM_Models('university'),
    SEM_Rulebases('OWL2RL'),
    null, null, null,
    ' PLUS_RDFT=VC ',
    null, null,
    'RDFUSER', 'RDF_NETWORK'))
ORDER BY s$rdfterm, type$rdfterm;


-- Q2: Who is an AIMajor? Expected: alice only
-- The TBox (ontology) has the rules to define who an AIMajor is, as someone who takes both CS601 and STAT201.  The ABox (instance) had information on the courses
-- Alice is taking.  From these two pieces of information the inference step inferred that Alice is an AIMajor.
SELECT s$rdfterm AS ai_major
  FROM TABLE(SEM_MATCH(
    'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
     PREFIX univ: <http://univ.org#>
     SELECT ?s
     WHERE { ?s rdf:type univ:AIMajor . }',
    SEM_Models('university'),
    SEM_Rulebases('OWL2RL'),
    null, null, null,
    ' PLUS_RDFT=VC ',
    null, null,
    'RDFUSER', 'RDF_NETWORK'));

-- Q4: Who is an Instructor? Expected: profA and drB
SELECT p$rdfterm AS instructor
  FROM TABLE(SEM_MATCH(
    'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
     PREFIX univ: <http://univ.org#>
     SELECT ?p
     WHERE { ?p rdf:type univ:Instructor . }',
    SEM_Models('university'),
    SEM_Rulebases('OWL2RL'),
    null, null, null,
    ' PLUS_RDFT=VC ',
    null, null,
    'RDFUSER', 'RDF_NETWORK'));


-- Q5: Who is a Professor? Expected: profA only
SELECT p$rdfterm AS professor
  FROM TABLE(SEM_MATCH(
    'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
     PREFIX univ: <http://univ.org#>
     SELECT ?p
     WHERE { ?p rdf:type univ:Professor . }',
    SEM_Models('university'),
    SEM_Rulebases('OWL2RL'),
    null, null, null,
    ' PLUS_RDFT=VC ',
    null, null,
    'RDFUSER', 'RDF_NETWORK'));


------------------------------------------------------------------------------------------------

-- Q6: Negative check - Bob is not an AI Major.  There is no instance data (triple) that says Bob is an AI Major (because he is only taking CS101)
SELECT COUNT(*) AS bob_ai_major_count
  FROM TABLE(SEM_MATCH(
    'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
     PREFIX univ: <http://univ.org#>
     SELECT ?s
     WHERE { univ:bob rdf:type univ:AIMajor .
             BIND(univ:bob AS ?s) }',
    SEM_Models('university'),
    SEM_Rulebases('OWL2RL'),
    null, null, null,
    ' PLUS_RDFT=VC ',
    null, null,
    'RDFUSER', 'RDF_NETWORK'));


-- Q7: Carol does not take both the AI and statistics courses, so she is not an AI major.
SELECT COUNT(*) AS carol_takes_ai_count
  FROM TABLE(SEM_MATCH(
    'PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
     PREFIX univ: <http://univ.org#>
     SELECT ?s
     WHERE { univ:carol rdf:type univ:TakesAICourse .
             BIND(univ:carol AS ?s) }',
    SEM_Models('university'),
    SEM_Rulebases('OWL2RL'),
    null, null, null,
    ' PLUS_RDFT=VC ',
    null, null,
    'RDFUSER', 'RDF_NETWORK'));


-- If you wish to clean up you work, you can simply drop the RDF_NETWORK
EXECUTE SEM_APIS.DROP_RDF_NETWORK(cascade=>TRUE, network_owner => 'RDFUSER', network_name => 'RDF_NETWORK');


