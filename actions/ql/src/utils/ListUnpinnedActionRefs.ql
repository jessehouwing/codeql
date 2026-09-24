/**
 * @name List candidate action refs for immutable-release verification
 * @description Lists distinct `(owner/repo, ref)` pairs used by `uses:` steps and reusable
 *              workflow calls that are not already pinned to a commit SHA, and are therefore
 *              candidates for checking against GitHub's Immutable Releases feature. This query
 *              is intended to be run as a pre-processing step (e.g. by a CI job) to build a list
 *              of `(action, ref)` pairs to verify via the GitHub API, whose results can then be
 *              fed back into CodeQL as an `immutableActionRefsDataModel` data extension for the
 *              `actions/unpinned-tag` query.
 * @kind table
 * @id actions/list-unpinned-action-refs
 * @tags utility
 *       actions
 */

import actions

bindingset[version]
private predicate isPinnedCommit(string version) {
  version.regexpMatch("^[A-Fa-f0-9]{40}([A-Fa-f0-9]{24})?$")
}

bindingset[nwo]
private predicate isContainerImage(string nwo) { nwo.regexpMatch("^docker://.+") }

// A `$/` reference is a same-repository (self repository) reference, resolved at the commit
// the calling workflow is running. Like `./` local references, it is inherently pinned.
bindingset[nwo]
private predicate isSelfRepository(string nwo) { nwo.matches("$/%") }

bindingset[nwo]
private string normalizeToRepo(string nwo) { result = nwo.regexpCapture("^([^/]+/[^/]+)(?:/.*)?$", 1) }

from Uses uses, string nwo, string version
where
  uses.getCallee() = nwo and
  uses.getVersion() = version and
  not isSelfRepository(nwo) and
  not isContainerImage(nwo) and
  not isPinnedCommit(version)
select normalizeToRepo(nwo) as action, version as ref
