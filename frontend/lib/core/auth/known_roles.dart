/// The 6 real roles, hardcoded — there is no `GET /api/roles` endpoint
/// (a known backend gap, see project memory / the Phase 1 API survey).
/// IDs confirmed stable via direct SQL query against the seeded `roles`
/// table. Used by the Workflow Designer's per-step role dropdown, which
/// needs role id+name pairs the backend doesn't expose any other way.
class KnownRole {
  const KnownRole(this.id, this.name);

  final int id;
  final String name;
}

const kDefaultRoleId = 1; // Records Officer — first entry of kKnownRoles, kept as a separate const since List.first isn't a const expression.

const kKnownRoles = <KnownRole>[
  KnownRole(1, 'Records Officer'),
  KnownRole(2, 'Approving Manager'),
  KnownRole(3, 'Finance Officer'),
  KnownRole(4, 'Records Manager'),
  KnownRole(5, 'System Administrator'),
  KnownRole(6, 'Internal Auditor'),
];
