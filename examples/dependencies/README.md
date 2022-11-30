# Dependencies Example

This example showcases project dependencies and extensions, it contains two
projects:

## Father
Defines the languages Ewokese with the function `mkFather`. This function takes
the childName and creates a text file with "$name: $childName I am your father" 

## Child
Depends on father and adds `mkChild` using `mkFather` from the father project.
`mkChild` runs `mkFather` and sets its name as childName and "Darth-Vader" as name.

Child also contains a component Luke which uses `mkChild` with "Luke" as name. The
result is a text file with
```
Darth-Vader: Luke, I am your father!
```
