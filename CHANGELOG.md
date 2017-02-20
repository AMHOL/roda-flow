# v0.3.1 - 2017-02-21

## Changed

- `r.resolve` request method now directly yields the resolved objects to the block, rather than relying on Roda's route matching system. This means that plugins depending on the current match block (like `r.pass`) are still useful inside `r.resolve` blocks (timriley)

# v0.3.0 - 2016-06-12

## Changed

- Removed hard dependency on roda-container plugin. Users of roda-flow can activate this plugin themselves or implement their own `.resolve(container_key)` method. (timriley)
