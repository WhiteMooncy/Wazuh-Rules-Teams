# Repository Structure

This repository currently contains two layers of content.

## Canonical Path

Use `Wazuh-Rules-Teams/` as the maintained project root.

That folder contains the complete factorized version:

- `docs/`: operational and change documentation
- `examples/`: configuration examples
- `integrations/`: Teams integration code
- `lists/`: CDB source lists
- `rules/`: active XML rules
- `scripts/`: testing and validation scripts

## Legacy Path

The top-level folders in the repository root are an older/minimal snapshot:

- `docs/`
- `examples/`
- `integrations/`
- `rules/`
- `scripts/`

Keep them only if you still need backward compatibility or historical reference.
Do not use them as the main source of truth for new changes.

## Current Recommended Navigation

1. Start at `Wazuh-Rules-Teams/README.md`.
2. Read `Wazuh-Rules-Teams/docs/README.md` for operational documentation.
3. Edit active rules under `Wazuh-Rules-Teams/rules/`.
4. Run tests from `Wazuh-Rules-Teams/scripts/`.

## Known Ambiguity

There is an empty folder at `Wazuh-Rules-Teams/Wazuh-Rules-Teams/`.
It does not contain active content and can be ignored.

## Practical Mental Model

- Repository root: wrapper and historical context
- `Wazuh-Rules-Teams/`: real working project
- `Wazuh-Rules-Teams/rules/`: detection logic
- `Wazuh-Rules-Teams/integrations/`: delivery logic
- `Wazuh-Rules-Teams/scripts/`: validation and simulation
- `Wazuh-Rules-Teams/docs/`: operator guidance
