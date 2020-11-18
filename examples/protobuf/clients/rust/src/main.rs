use ext::ext::DependingOnIt;
use base::diplodocus::foundation::DependOnMe;

// Ext already depends on base.
// The goal here is to use both types DependOnMe
// inside ext and base to ensure they are the same.

fn main() {
    let same_type = DependingOnIt {
        here: Some(DependOnMe {
            yes: "Hooray!".to_owned(),
        }),
    };

    println!("{:#?}", same_type);
}

#[cfg(test)]
#[test]
fn test_main() {
    main();
}
