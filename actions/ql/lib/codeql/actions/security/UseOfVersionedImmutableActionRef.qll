/**
 * Provides a class and predicate for identifying uses of Actions pinned to a tag/ref that is
 * known to point to an immutable release (GitHub's Immutable Releases feature). Unlike
 * `UseOfUnversionedImmutableAction.qll`, which relies on a static, repo-level allow-list of
 * actions that were part of the older, more limited immutable-actions preview, this module
 * consumes a per-`(action, ref)` data model, because immutability under the Immutable Releases
 * feature is a property of an individual tag/release, not of the repository as a whole -- not
 * every tag of an action's repository is guaranteed to be immutable.
 *
 * The `(action, ref)` data is expected to be populated externally (e.g. by a pre-processing step
 * that queries the GitHub GraphQL API for the `immutable` flag on each referenced release) and
 * supplied via the `immutableActionRefsDataModel` extensible predicate.
 */

import actions

bindingset[nwo]
private string normalizeToRepo(string nwo) {
  // Immutability is a property of the repository + tag/release, not of the specific
  // sub-directory action being referenced (e.g. `owner/repo/path/to/action@ref`), so we
  // normalize to just the `owner/repo` portion before consulting the data model.
  result = nwo.regexpCapture("^([^/]+/[^/]+)(?:/.*)?$", 1)
}

/**
 * Holds if `actionStep` uses `actionName` (which may include a sub-directory path) pinned to
 * `ref`, and `ref` is known to point to an immutable release of `actionName`'s repository.
 */
predicate isImmutableActionRef(UsesStep actionStep, string actionName, string ref) {
  actionStep.getCallee() = actionName and
  actionStep.getVersion() = ref and
  immutableActionRefsDataModel(normalizeToRepo(actionName), ref)
}

/** A `UsesStep` that is pinned to a tag/ref known to point to an immutable release. */
class VersionedImmutableActionRef extends UsesStep {
  VersionedImmutableActionRef() { isImmutableActionRef(this, this.getCallee(), this.getVersion()) }
}
