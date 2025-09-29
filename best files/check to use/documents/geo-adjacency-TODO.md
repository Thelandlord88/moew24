## Adjacency Outstanding Items (Post K_BASE 9 Tuning)

Current tuned parameters (see `config/adj.config.json`) improved mean degree & reduced components to 5, but 2 isolates remain:

- kooringal (nearest neighbor ~17.8 km)
- moreton-bay (nearest ~6.65 km but pruned / not mutual)

Lake-manchester and lyons were healed by increased K_BASE + extended prune retention.

Planned next steps:
1. Special-case bridge insertion for remote maritime / island nodes (cap labeled as synthetic edge) OR classify as permissible isolates (update policy.minFloor exception list).
2. Evaluate raising `MAX_KM_EXT` to 18 selectively for nodes with degree=0.
3. Add optional `--force-bridges path/to/bridges.json` to builder.

Cross-cluster leakage remains low (ratio 0.0266) under stricter connectivity; safe headroom.

Created: 2025-09-15
