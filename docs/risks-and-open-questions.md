# Risks And Open Questions

## Risks

- shared-core drift: framework concerns can leak into the application layer if runtime adapters are not kept thin
- persistence divergence: Spring and Quarkus adapters can evolve different behavior if API contracts are not tested centrally
- native image friction: reflection-heavy libraries or serialization defaults may complicate the Quarkus native path later
- template-rule sprawl: parameter conventions can become scattered if they are not modeled in one core policy
- stub blindness: a simplistic renderer can hide file streaming or content-type issues until later

## Open Questions

- should v1 support only `TXT` output first, or is a minimal valid `PDF` output required from the start?
- should `parameters` remain `Map<String, String>` in the API, or must typed JSON values be supported immediately?
- should history stay unpaginated in v1, or should pagination be included from the first public contract?
- should both runtimes eventually share migration scripts, or should each module own its database setup independently?
- which persistence style best serves the comparison goal: framework-native repositories or a more shared JPA layer?

## Current Assumptions

- v1 can start with a small fixed enum set for `TemplateType` and `DocumentFormat`
- request history returns stored request metadata and parameters, not generated file content
- the first implementation slice can use in-memory persistence if it preserves the repository contract and shortens the time to a working comparison baseline
