use ext::ext::DependingOnIt;

// Note that since there is only one top level protobuf package in the crate base.
// We re-export everything inside this top level package
// so base:: and base::diplodocus are equivalent.
use base::diplodocus::foundation::DependOnMe;
use base::roof::Tile; // = base::diplodocus::roof::Tile

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

    let tile = Tile {
        yes: None,
        am_i_roof_tile: false,
    };

    println!("{:#?}", tile);
}

#[cfg(test)]
#[test]
fn test_main() {
    main();
}
