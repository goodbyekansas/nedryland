use std::{
    collections::HashMap,
    fs::{self, OpenOptions},
    io::Write,
    path::{Path, PathBuf},
};

use structopt::StructOpt;

#[derive(Debug, StructOpt)]
#[structopt(name = "compiler", about = "A simple rust protoc command line")]
struct Options {
    /// Input proto files
    #[structopt(parse(from_os_str))]
    files: Vec<PathBuf>,

    /// Output folder
    #[structopt(short = "o", long = "out", default_value = ".", parse(from_os_str))]
    out_dir: PathBuf,

    /// Proto include paths
    #[structopt(short = "I", long = "include", parse(from_os_str))]
    includes: Vec<PathBuf>,

    /// Proto external crates
    #[structopt(short = "e", long = "extern", parse(try_from_str = parse_key_val))]
    externs: Vec<(String, String)>,

    /// determines if services should be included in the build output
    #[structopt(short = "s", long = "build-services")]
    build_services: bool,
}

fn parse_key_val(s: &str) -> Result<(String, String), Box<dyn std::error::Error>> {
    let pos = s
        .find('=')
        .ok_or_else(|| format!("invalid KEY=value: no `=` found in `{}`", s))?;
    Ok((s[..pos].parse()?, s[pos + 1..].parse()?))
}

#[derive(Clone, Default)]
struct Entry {
    include_file: Option<PathBuf>,
    modules: HashMap<String, Entry>,
}

fn create_module_tree(root_path: &Path, mut root: Entry, paths: &[String], index: usize) -> Entry {
    // determine how to update the root node before returning it
    match (index + 1).cmp(&paths.len()) {
        // leaf node, reconstruct the file path from parts again
        std::cmp::Ordering::Equal => {
            let e = root.modules.entry(paths[index].clone()).or_default();
            e.include_file = Some(root_path.join(format!("{}.rs", paths.join("."))));
        }
        // inner node, insert and update the entry at `paths[index]`
        std::cmp::Ordering::Less => {
            let e = root.modules.entry(paths[index].clone()).or_default();
            *e = create_module_tree(root_path, e.clone(), paths, index + 1);
        }
        // list is empty or index out of range, simply return the original root
        std::cmp::Ordering::Greater => {}
    }

    root
}

fn create_structure(path: &Path, root: &Entry, is_lib_rs: bool) -> Result<(), std::io::Error> {
    let mut target_file = path.to_owned();
    target_file.set_extension("rs");
    target_file.parent().map_or(Ok(()), fs::create_dir_all)?;

    // 🤮
    let path = if is_lib_rs {
        path.parent().map(|p| p.to_owned()).unwrap_or_default()
    } else {
        path.to_owned()
    };

    OpenOptions::new()
        .create_new(true)
        .write(true)
        .open(&target_file)
        .and_then(|mut file| {
            // insert pub mod statements for each module
            writeln!(file, "// Generated, not intended for editing!")?;
            let mut mods: Vec<&String> = root.modules.keys().collect();
            mods.sort();
            mods.iter()
                .try_for_each(|path_name| writeln!(file, "pub mod {};", path_name))?;

            if is_lib_rs && mods.len() == 1 {
                mods.first()
                    .map(|path_name| writeln!(file, "pub use crate::{}::*;", path_name))
                    .transpose()?;
            }

            // include content and remove original
            root.include_file.as_ref().map_or(Ok(()), |include| {
                writeln!(file)?;
                write!(file, "{}", fs::read_to_string(include)?)
            })
        })?;

    // do the same for all modules
    root.modules
        .iter()
        .try_for_each(|(pathname, entry)| create_structure(&path.join(pathname), entry, false))
}

fn main() {
    let options = Options::from_args();
    let origpath = options.out_dir.join(".orig");
    if let Err(e) = fs::create_dir_all(&origpath)
        .and_then(|_| {
            let mut prost_conf = prost_build::Config::new();
            options.externs.iter().for_each(|e| {
                prost_conf.extern_path(e.0.to_owned(), e.1.to_owned());
            });

            tonic_build::configure()
                .out_dir(&origpath)
                .build_client(options.build_services)
                .build_server(options.build_services)
                .compile_with_config(prost_conf, &options.files, &options.includes)
        })
        .and_then(|_| {
            fs::read_dir(&origpath)?
                .map(|f_res| {
                    f_res
                        .and_then(|f| {
                            // prost generates a single new line for unneeded files
                            if f.metadata()?.len() <= 1 {
                                Ok(None)
                            } else {
                                Ok(f.path()
                                    .file_stem()
                                    .map(|fs| fs.to_string_lossy().to_string()))
                            }
                        })
                        .transpose()
                })
                .filter_map(|f| f) // skip all files without filename
                .map(|rf| rf.map(|f| f.split('.').map(str::to_owned).collect::<Vec<String>>()))
                .try_fold(Entry::default(), |entry, rlist| {
                    rlist.map(|list| create_module_tree(&origpath, entry, &list, 0))
                })
        })
        .and_then(|tree| create_structure(&options.out_dir.join("lib"), &tree, true))
        .and_then(|_| fs::remove_dir_all(&origpath))
    {
        eprintln!("{}", e);
        std::process::exit(1);
    };
}
