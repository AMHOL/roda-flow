# v0.4.0 - 2018-02-07

## Changed

- `flow_defaults` method added for setting default `inject` and `call_with` arguments in a flow ([fleadope](https://github.com/fleadope))

## Fixed

- `if_match` updated to match latest Roda version and stop wildcard matching routes ([see discussion](https://discourse.dry-rb.org/t/dry-web-roda-roda-flow-plugin-causing-routing-wildcard/461)) ([AMHOL](https://github.com/AMHOL))

# v0.3.1 - 2017-02-21

## Changed

- `r.resolve` request method now directly yields the resolved objects to the block, rather than relying on Roda's route matching system. This means that plugins depending on the current match block (like `r.pass`) are still useful inside `r.resolve` blocks ([timriley](https://github.com/timriley))

# v0.3.0 - 2016-06-12

## Changed

- Removed hard dependency on roda-container plugin. Users of roda-flow can activate this plugin themselves or implement their own `.resolve(container_key)` method. ([timriley](https://github.com/timriley))
