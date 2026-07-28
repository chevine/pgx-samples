# University Ontology RDF Example

This runnable example creates a small university RDF graph in Oracle AI Database. It loads an OWL ontology and instance data, creates an OWL 2 RL inferred graph, and runs SPARQL queries through the `SEM_MATCH` SQL table function.

The example illustrates class hierarchies, object and datatype properties, and inference. In particular, it infers that Alice is an `AIMajor` because she takes an AI course and a statistics course.

## Prerequisites

- Oracle AI Database with RDF Semantic Graph support.
- A database user named `RDFUSER` with the required RDF privileges.
- A tablespace available for the RDF network.
- A SQL client that supports SQL*Plus commands, such as SQLcl or SQL Developer.

The script creates an RDF network named `RDF_NETWORK` and graph models named `university` and `univ_inf` in the `RDFUSER` schema. Use a dedicated schema or change these names before running it in a shared environment.

## Run the Example

1. Open [`university-ontology.sql`](university-ontology.sql) in a SQL client and connect as `RDFUSER`.
2. Replace `<tablespace_name>` in the `CREATE_RDF_NETWORK` call with an available tablespace name.
3. Run the script in order.

The script creates the RDF network, loads the ontology (TBox) and university facts (ABox), adds the AI-course classification, and materializes OWL 2 RL inferences.

## Expected Results

- The first `AICourse` query returns no rows; after the additional classification is loaded, it returns `courseCS601`.
- The inferred-course query includes `courseSTAT201` as a `Course` because `StatisticsCourse` is a subclass of `Course`.
- The `AIMajor` query returns `alice`.
- The `Instructor` query returns `profA` and `drB`; the `Professor` query returns `profA`.
- The negative checks for Bob and Carol return `0`.

## Cleanup

The last statement drops `RDF_NETWORK` with `cascade=>TRUE`. Leave it enabled only when the network is dedicated to this example. Remove or comment out that statement if you want to inspect the graph after the script completes.

## Files

| Path | Purpose |
| --- | --- |
| [`university-ontology.sql`](university-ontology.sql) | Creates, loads, queries, and optionally removes the university RDF graph. |

## Related Links

- RDF examples: [`../../`](../../)
- Oracle property graph examples: [`../../../property-graph/`](../../../property-graph/)
