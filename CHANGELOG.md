*   Add generators.

    For example:

    ```
      bin/rails g tailor_made:dashboard Ahoy::Visits
    ```

    Generates a controller, query class and adds views.

    *Pedro Carmona*

*   Fix metaprogramming.

    Was creating the arrays in the base query class, moved declaration to children.

    *Pedro Carmona*


## TailorMade 0.0.1 (March 17, 2019) ##

*   Initial source code
