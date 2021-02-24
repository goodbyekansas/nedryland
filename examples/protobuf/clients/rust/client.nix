{ base, protocols, baseProtocols }:
base.languages.rust.mkClient {
  name = "rust-client";
  buildInputs = [ protocols.rust.package ];
  src = ./.;
  externalDependenciesHash = "sha256-OwxIfRrYeqMFYrtBZ9s6BIk6ifUazhvNwiWImxdhUBw=";
}
