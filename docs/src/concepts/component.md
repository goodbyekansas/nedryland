# Component

A component is the most fundamental building block in Nedryland and the architechtural building
block in a microservice based system.

Nedryland contains plenty of helper functions to create different kinds of components. Components
can furthermore be dependent on eachother and Nedryland also contains many helpers for deployment of
components.

## Base

In addition to the package collection, components also get access to something called _base_.
_base_ is a collection of Nedryland utilities for component declaration so it is essentially a big
set of functions that relates to declaring components. The set of functions available in base can
also be extended by other projects as described [here](../declare-project.md#extensions).
