combined: assertMsg:
assert assertMsg
  (combined.sortedDeployments == [
    "firstArtifact"
    "specificArtifact"
    "anotherArtifact"
    "lastArtifact"
  ])
  "Combined deployments did not have expected order.";
{ }
