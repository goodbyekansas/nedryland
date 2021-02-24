# Matrix

A central concept in Nedryland is the matrix. The matrix is how build targets are accessed and the
reason it is called a matrix is since the target layout can be thought of as a two-axis matrix. On one
axis, we have all components and on the other axis, we have all targets. In addition to this, there
are also some one-dimensional targets that always work on all components (deployment is usually one
example).

An example matrix might look like:

| ⬇️ component \ target ➡️ | package | docs | target1 | target2 |
|------------------------|---------|------|---------|---------|
| nedry                  |         |      |         |         |
| hammond                |         |      |         |         |
| malcolm                |         |      |         |         |

This means that to build the `package` target of `hammond` we would access `hammond.package`:

| ⬇️ component \ target ➡️ | package | docs | target1 | target2 |
|------------------------|:-------:|:----:|:-------:|:-------:|
| nedry                  |         |      |         |         |
| hammond                |    🧨   |      |         |         |
| malcolm                |         |      |         |         |

To build all targets for `hammond`, we would access `hammond`:

| ⬇️ component \ target ➡️ | package | docs | target1 | target2 |
|------------------------|:-------:|:----:|:-------:|:-------:|
| nedry                  |         |      |         |         |
| hammond                |    🧨   |  🧨  |    🧨   |    🧨   |
| malcolm                |         |      |         |         |

and to build the target `package` for all components we would simply access `package`:


| ⬇️ component \ target ➡️ | package | docs | target1 | target2 |
|------------------------|:-------:|:----:|:-------:|:-------:|
| nedry                  |    🧨   |      |         |         |
| hammond                |    🧨   |      |         |         |
| malcolm                |    🧨   |      |         |         |
